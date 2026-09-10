use serde::Serialize;
use serde_json::{json, Value};
use std::{
    env, fs,
    io::{BufRead, BufReader, Write},
    path::{Path, PathBuf},
    process::{Child, ChildStdin, Command, Stdio},
    sync::mpsc::{self, Receiver},
    time::{Duration, Instant, SystemTime, UNIX_EPOCH},
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
    daily_usage: Option<Vec<Value>>,
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
                    service.daily_usage = Some(buckets.clone());
                }
            }
        }
        Err(error) => service.error = Some(error),
    }
    service
}

fn parse_codex_limits(value: &Value) -> Vec<Limit> {
    if let Some(buckets) = value.get("rateLimitsByLimitId").and_then(Value::as_object) {
        return buckets
            .iter()
            .flat_map(|(name, bucket)| {
                let mut limits = parse_codex_limits(bucket);
                if name != "codex" {
                    for limit in &mut limits {
                        limit.title = format!("{name} · {}", limit.title);
                    }
                }
                limits
            })
            .collect();
    }
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
    child: Child,
    input: ChildStdin,
    output: Receiver<Result<Value, String>>,
}

impl Drop for AppServer {
    fn drop(&mut self) {
        let _ = self.child.kill();
        let _ = self.child.wait();
    }
}

impl AppServer {
    fn start() -> Result<Self, String> {
        let mut child = Command::new(
            find_codex()
                .ok_or("Windows용 Codex CLI를 설치하고 로그인한 후 이 앱을 다시 실행하세요.")?,
        )
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
        let mut output = BufReader::new(child.stdout.take().ok_or("Codex 출력 연결 실패")?);
        let (sender, receiver) = mpsc::sync_channel(1);
        std::thread::spawn(move || {
            use std::io::Read;
            loop {
                let mut line = String::new();
                // Bound a malformed/oversized reply instead of retaining an unlimited line.
                match output
                    .by_ref()
                    .take(8 * 1024 * 1024 + 1)
                    .read_line(&mut line)
                {
                    Ok(0) | Err(_) => break,
                    Ok(_) if line.len() > 8 * 1024 * 1024 => {
                        let _ = sender.send(Err("Codex 응답 크기 초과".into()));
                        break;
                    }
                    Ok(_) => {
                        if let Ok(value) = serde_json::from_str(&line) {
                            if sender.send(Ok(value)).is_err() {
                                break;
                            }
                        }
                    }
                }
            }
        });
        let mut server = Self {
            child,
            input,
            output: receiver,
        };
        server.request(
            1,
            "initialize",
            json!({
                "clientInfo": {"name": "codex-claude-info", "title": "Codex & Claude Info", "version": env!("CARGO_PKG_VERSION")},
                "capabilities": {"experimentalApi": true}
            }),
        )?;
        server.write(&json!({"method": "initialized", "params": {}}))?;
        Ok(server)
    }

    fn request(&mut self, id: u64, method: &str, params: Value) -> Result<Value, String> {
        self.write(&json!({"id": id, "method": method, "params": params}))?;
        let deadline = Instant::now() + Duration::from_secs(15);
        loop {
            let value = self
                .output
                .recv_timeout(deadline.saturating_duration_since(Instant::now()))
                .map_err(|_| {
                    "Codex 응답 시간 초과 또는 연결 종료. 로그인 상태를 확인하세요.".to_string()
                })??;
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
        let Some(modified) = entry.metadata().ok().and_then(|m| m.modified().ok()) else {
            continue;
        };
        if newest.as_ref().is_some_and(|(date, _)| *date >= modified) {
            continue;
        }
        let Some(value) = fs::read(entry.path())
            .ok()
            .and_then(|data| serde_json::from_slice::<Value>(&data).ok())
        else {
            continue;
        };
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
    text.lines()
        .take_while(|line| !line.trim().starts_with('['))
        .find_map(|line| {
            let line = line.trim();
            let (key, value) = line.split_once('=')?;
            (key.trim() == "model").then(|| value.trim().trim_matches('"').to_owned())
        })
}

fn find_codex() -> Option<PathBuf> {
    let mut roots: Vec<PathBuf> = env::var_os("PATH")
        .map(|paths| env::split_paths(&paths).collect())
        .unwrap_or_default();
    if let Some(home) = env::var_os("USERPROFILE") {
        roots.push(PathBuf::from(home).join(".local/bin"));
    }
    if let Some(appdata) = env::var_os("APPDATA") {
        roots.push(PathBuf::from(appdata).join("npm"));
    }
    if let Some(local) = env::var_os("LOCALAPPDATA") {
        roots.push(PathBuf::from(local).join("Programs/OpenAI/Codex/bin"));
    }
    for root in &roots {
        let executable = root.join(if cfg!(windows) { "codex.exe" } else { "codex" });
        if executable.is_file() {
            return Some(executable);
        }
    }
    // npm exposes a .cmd shim; execute its native binary to avoid a persistent shell.
    for root in roots {
        for entry in WalkDir::new(root.join("node_modules/@openai"))
            .max_depth(9)
            .into_iter()
            .filter_map(Result::ok)
        {
            if entry.file_type().is_file() && entry.file_name() == "codex.exe" {
                return Some(entry.into_path());
            }
        }
    }
    None
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

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn reads_named_buckets_and_does_not_invent_missing_limits() {
        let limits = parse_codex_limits(&json!({"rateLimitsByLimitId": {
            "codex": {"primary": {"usedPercent": 12.5, "windowDurationMins": 300, "resetsAt": 123}},
            "extra": {"secondary": {"usedPercent": 42, "windowDurationMins": 10080}}
        }}));
        assert_eq!(limits.len(), 2);
        assert_eq!(limits[0].used_percent, 12.5);
        assert_eq!(limits[0].resets_at, Some(123));
        assert_eq!(limits[1].title, "extra · 주간 사용량");
        assert_eq!(limits[1].resets_at, None);
        assert!(parse_codex_limits(&json!({"rateLimits": null})).is_empty());
    }
}
