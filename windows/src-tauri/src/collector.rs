use serde::Serialize;
use serde_json::{json, Value};
use std::{
    env, fs,
    io::{BufRead, BufReader, Write},
    path::{Path, PathBuf},
    process::{Child, ChildStdin, ChildStdout, Command, Stdio},
    time::{SystemTime, UNIX_EPOCH},
};
use walkdir::WalkDir;

#[derive(Default, Serialize)]
pub struct Dashboard {
    codex: Service,
    claude: Service,
    updated_at: u64,
}

#[derive(Default, Serialize)]
pub struct Service {
    connected: bool,
    source: String,
    model: Option<String>,
    effort: Option<String>,
    task: Option<String>,
    yesterday_tokens: u64,
    week_tokens: u64,
    limits: Vec<Limit>,
    error: Option<String>,
}

#[derive(Serialize)]
pub struct Limit {
    title: String,
    used_percent: f64,
    window_minutes: u64,
    resets_at: Option<u64>,
}

pub fn collect() -> Dashboard {
    Dashboard {
        codex: collect_codex(),
        claude: collect_claude(),
        updated_at: now(),
    }
}

fn collect_codex() -> Service {
    let mut service = Service {
        source: "Codex app-server".into(),
        model: configured_codex_model(),
        ..Default::default()
    };
    match AppServer::start() {
        Ok(mut server) => {
            let rates = server.request(2, "account/rateLimits/read", json!({}));
            let usage = server.request(3, "account/usage/read", json!({}));
            match rates {
                Ok(value) => {
                    service.connected = true;
                    service.limits = parse_codex_limits(&value);
                }
                Err(error) => service.error = Some(error),
            }
            if let Ok(value) = usage {
                let buckets = value
                    .pointer("/dailyUsageBuckets")
                    .or_else(|| value.pointer("/result/dailyUsageBuckets"))
                    .and_then(Value::as_array);
                if let Some(buckets) = buckets {
                    let mut tokens: Vec<u64> = buckets
                        .iter()
                        .filter_map(|item| item.get("tokens").and_then(Value::as_u64))
                        .collect();
                    service.week_tokens = tokens.iter().rev().take(7).sum();
                    service.yesterday_tokens = tokens.pop().unwrap_or(0);
                }
            }
        }
        Err(error) => service.error = Some(error),
    }
    service
}

fn parse_codex_limits(value: &Value) -> Vec<Limit> {
    let root = value.get("rateLimits").unwrap_or(value);
    [("primary", "단기 사용량"), ("secondary", "주간 사용량")]
        .into_iter()
        .filter_map(|(key, title)| {
            let item = root.get(key)?;
            Some(Limit {
                title: title.into(),
                used_percent: item.get("usedPercent")?.as_f64()?,
                window_minutes: item.get("windowDurationMins")?.as_u64()?,
                resets_at: item.get("resetsAt").and_then(Value::as_u64),
            })
        })
        .collect()
}

struct AppServer {
    _child: Child,
    input: ChildStdin,
    output: BufReader<ChildStdout>,
}

impl AppServer {
    fn start() -> Result<Self, String> {
        let mut child = Command::new("codex")
            .arg("app-server")
            .stdin(Stdio::piped())
            .stdout(Stdio::piped())
            .stderr(Stdio::null())
            .creation_flags_no_window()
            .spawn()
            .map_err(|_| {
                "Codex CLI를 찾을 수 없습니다. Windows용 Codex를 설치하고 로그인하세요.".to_string()
            })?;
        let input = child.stdin.take().ok_or("Codex 입력 연결 실패")?;
        let output = BufReader::new(child.stdout.take().ok_or("Codex 출력 연결 실패")?);
        let mut server = Self {
            _child: child,
            input,
            output,
        };
        server.request(
            1,
            "initialize",
            json!({
                "clientInfo": {"name": "codex-claude-info", "title": "Codex & Claude Info", "version": "0.1.0"},
                "capabilities": {"experimentalApi": true}
            }),
        )?;
        server.write(&json!({"method": "initialized", "params": {}}))?;
        Ok(server)
    }

    fn request(&mut self, id: u64, method: &str, params: Value) -> Result<Value, String> {
        self.write(&json!({"id": id, "method": method, "params": params}))?;
        let mut line = String::new();
        loop {
            line.clear();
            if self
                .output
                .read_line(&mut line)
                .map_err(|e| e.to_string())?
                == 0
            {
                return Err("Codex 연결이 종료되었습니다.".into());
            }
            let value: Value = match serde_json::from_str(&line) {
                Ok(value) => value,
                Err(_) => continue,
            };
            if value.get("id").and_then(Value::as_u64) != Some(id) {
                continue;
            }
            if let Some(error) = value.pointer("/error/message").and_then(Value::as_str) {
                return Err(error.into());
            }
            return value
                .get("result")
                .cloned()
                .ok_or("Codex 응답 형식 오류".into());
        }
    }

    fn write(&mut self, value: &Value) -> Result<(), String> {
        writeln!(self.input, "{value}").map_err(|e| e.to_string())?;
        self.input.flush().map_err(|e| e.to_string())
    }
}

fn collect_claude() -> Service {
    let appdata = env::var_os("APPDATA").map(PathBuf::from);
    let mut service = Service {
        source: "Claude Desktop 로컬 데이터".into(),
        ..Default::default()
    };
    let Some(root) = appdata.map(|path| path.join("Claude")) else {
        service.error = Some("APPDATA 경로를 찾을 수 없습니다.".into());
        return service;
    };

    if let Some((model, effort, task)) = newest_claude_session(&root.join("claude-code-sessions")) {
        service.connected = true;
        service.model = model;
        service.effort = effort;
        service.task = task;
    }
    if let Some((five, seven)) = claude_plan_usage(&root.join("plan-usage-history.json")) {
        service.connected = true;
        service.limits = vec![
            Limit {
                title: "5시간 사용량".into(),
                used_percent: five,
                window_minutes: 300,
                resets_at: None,
            },
            Limit {
                title: "7일 사용량".into(),
                used_percent: seven,
                window_minutes: 10_080,
                resets_at: None,
            },
        ];
    }
    if !service.connected {
        service.error =
            Some("Claude Desktop 또는 Claude Code 사용 기록을 아직 찾지 못했습니다.".into());
    }
    service
}

fn newest_claude_session(root: &Path) -> Option<(Option<String>, Option<String>, Option<String>)> {
    let mut newest: Option<(SystemTime, Value)> = None;
    for entry in WalkDir::new(root).into_iter().filter_map(Result::ok) {
        if entry.path().extension().and_then(|value| value.to_str()) != Some("json") {
            continue;
        }
        let modified = entry.metadata().ok()?.modified().ok()?;
        if newest.as_ref().is_some_and(|(date, _)| *date >= modified) {
            continue;
        }
        let value: Value = serde_json::from_slice(&fs::read(entry.path()).ok()?).ok()?;
        if value.get("sessionId").is_some() {
            newest = Some((modified, value));
        }
    }
    let value = newest?.1;
    Some((
        value
            .get("model")
            .and_then(Value::as_str)
            .map(str::to_owned),
        value
            .get("effort")
            .and_then(Value::as_str)
            .map(str::to_owned),
        value
            .get("title")
            .and_then(Value::as_str)
            .map(str::to_owned),
    ))
}

fn claude_plan_usage(path: &Path) -> Option<(f64, f64)> {
    let value: Value = serde_json::from_slice(&fs::read(path).ok()?).ok()?;
    let sample = value
        .get("samples")?
        .as_array()?
        .iter()
        .max_by_key(|sample| sample.get("t").and_then(Value::as_u64))?;
    Some((
        sample.pointer("/u/fh")?.as_f64()?,
        sample.pointer("/u/sd")?.as_f64()?,
    ))
}

fn configured_codex_model() -> Option<String> {
    let home = env::var_os("USERPROFILE").map(PathBuf::from)?;
    let text = fs::read_to_string(home.join(".codex").join("config.toml")).ok()?;
    text.lines().find_map(|line| {
        let line = line.trim();
        line.strip_prefix("model").and_then(|rest| {
            rest.split_once('=')
                .map(|(_, value)| value.trim().trim_matches('"').to_owned())
        })
    })
}

fn now() -> u64 {
    SystemTime::now()
        .duration_since(UNIX_EPOCH)
        .unwrap_or_default()
        .as_secs()
}

#[cfg(windows)]
trait NoWindow {
    fn creation_flags_no_window(&mut self) -> &mut Self;
}

#[cfg(windows)]
impl NoWindow for Command {
    fn creation_flags_no_window(&mut self) -> &mut Self {
        use std::os::windows::process::CommandExt;
        self.creation_flags(0x08000000)
    }
}

#[cfg(not(windows))]
trait NoWindow {
    fn creation_flags_no_window(&mut self) -> &mut Self;
}

#[cfg(not(windows))]
impl NoWindow for Command {
    fn creation_flags_no_window(&mut self) -> &mut Self {
        self
    }
}
