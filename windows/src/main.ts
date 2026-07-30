import { invoke } from "@tauri-apps/api/core";
import "./style.css";

type Limit = {
  title: string;
  used_percent: number;
  window_minutes: number;
  resets_at?: number;
};

type Service = {
  connected: boolean;
  source: string;
  model?: string;
  effort?: string;
  task?: string;
  yesterday_tokens: number;
  week_tokens: number;
  limits: Limit[];
  error?: string;
};

type Dashboard = {
  codex: Service;
  claude: Service;
  updated_at: number;
};

const empty: Dashboard = {
  codex: { connected: false, source: "대기 중", yesterday_tokens: 0, week_tokens: 0, limits: [] },
  claude: { connected: false, source: "대기 중", yesterday_tokens: 0, week_tokens: 0, limits: [] },
  updated_at: 0
};

let selected: "codex" | "claude" = "codex";
let data = empty;
let loading = true;
let customPetUrl: string | undefined;
let customPetName = "짱구 코디";
const isTauri = "__TAURI_INTERNALS__" in window;

const app = document.querySelector<HTMLDivElement>("#app")!;

function compact(value: number): string {
  if (value >= 100_000_000) return `${(value / 100_000_000).toFixed(1)}억`;
  if (value >= 10_000) return `${(value / 10_000).toFixed(1)}만`;
  if (value >= 1_000) return `${(value / 1_000).toFixed(1)}천`;
  return value.toLocaleString("ko-KR");
}

function countdown(timestamp?: number): string {
  if (!timestamp) return "리셋 시각 확인 중";
  const seconds = Math.max(0, Math.floor(timestamp - Date.now() / 1000));
  const days = Math.floor(seconds / 86400);
  const hours = Math.floor((seconds % 86400) / 3600);
  const minutes = Math.floor((seconds % 3600) / 60);
  return days ? `${days}일 ${hours}시간` : hours ? `${hours}시간 ${minutes}분` : `${minutes}분 후 리셋`;
}

function escapeHtml(value: string): string {
  return value.replace(/[&<>"']/g, character => ({
    "&": "&amp;", "<": "&lt;", ">": "&gt;", '"': "&quot;", "'": "&#039;"
  })[character]!);
}

function serviceView(service: Service): string {
  const petState = service.error ? "failed" : service.connected ? "active" : "idle";
  const petStyle = customPetUrl ? ` style="background-image:url('${customPetUrl}')"` : "";
  return `
    <section class="hero">
      <div class="pet ${customPetUrl ? "custom" : petState}"${petStyle} aria-label="${escapeHtml(customPetName)}"></div>
      <div>
        <h1>${selected === "codex" ? "Codex" : "Claude"} Info</h1>
        <p>${escapeHtml(customPetName)}</p>
        <span class="status ${service.connected ? "ok" : "warn"}">
          ${service.connected ? "● 연결됨" : "● 연결 대기"}
        </span>
        <div class="pet-actions">
          <button id="choose-pet">펫 변경</button>
          ${customPetUrl ? '<button id="reset-pet">기본 펫</button>' : ""}
        </div>
      </div>
    </section>

    <section class="card task">
      <span class="bolt">⚡</span>
      <div><strong>${service.task || "최근 작업 대기 중"}</strong><small>${service.source}</small></div>
      ${loading ? '<span class="spinner"></span>' : ""}
    </section>

    ${service.limits.length
      ? service.limits.map(limit => `
        <section class="card limit">
          <div class="row"><strong>${limit.title}</strong><span>${Math.round(limit.used_percent)}% 사용</span></div>
          <div class="track"><i style="width:${Math.min(100, limit.used_percent)}%"></i></div>
          <div class="row muted"><span>${limit.window_minutes >= 1440 ? `${limit.window_minutes / 1440}일` : `${limit.window_minutes / 60}시간`} 한도</span><span>◷ ${countdown(limit.resets_at)}</span></div>
        </section>`).join("")
      : `<section class="card empty">사용량 정보를 기다리고 있습니다.</section>`}

    ${service.error ? `<section class="card error">⚠ ${service.error}</section>` : ""}

    <section class="card metrics">
      <h2>▥ 사용량</h2>
      <div class="metric-grid">
        <div><b>${compact(service.yesterday_tokens)}</b><span>어제 토큰</span></div>
        <div><b>${compact(service.week_tokens)}</b><span>최근 7일</span></div>
        <div><b>${service.connected ? "정상" : "대기"}</b><span>연결 상태</span></div>
      </div>
    </section>

    <section class="card model">
      <h2>▣ 모델</h2>
      <div class="row"><div><strong>${service.model || "모델 확인 중"}</strong><small>현재 ${selected === "codex" ? "Codex" : "Claude"} 모델</small></div><em>${service.effort || "기본 추론"}</em></div>
    </section>`;
}

function render(): void {
  const service = data[selected];
  app.innerHTML = `
    <main>
      <nav>
        <span>서비스</span>
        <button data-tab="codex" class="${selected === "codex" ? "selected" : ""}">Codex</button>
        <button data-tab="claude" class="${selected === "claude" ? "selected" : ""}">Claude</button>
      </nav>
      ${serviceView(service)}
      <input id="pet-file" type="file" accept="image/png,image/jpeg,image/webp,image/gif" hidden />
      <footer>
        <span>${data.updated_at ? new Date(data.updated_at * 1000).toLocaleTimeString("ko-KR", {hour: "2-digit", minute: "2-digit"}) : "업데이트 전"}</span>
        <button id="refresh">↻ 새로고침</button>
        <button id="quit">종료</button>
      </footer>
    </main>`;

  document.querySelectorAll<HTMLButtonElement>("[data-tab]").forEach(button => {
    button.onclick = () => {
      selected = button.dataset.tab as "codex" | "claude";
      render();
    };
  });
  document.querySelector<HTMLButtonElement>("#refresh")!.onclick = refresh;
  document.querySelector<HTMLButtonElement>("#quit")!.onclick = () => invoke("quit_app");
  const petInput = document.querySelector<HTMLInputElement>("#pet-file")!;
  document.querySelector<HTMLButtonElement>("#choose-pet")!.onclick = () => petInput.click();
  petInput.onchange = () => {
    const file = petInput.files?.[0];
    if (file) void savePet(file);
  };
  const resetButton = document.querySelector<HTMLButtonElement>("#reset-pet");
  if (resetButton) resetButton.onclick = () => void resetPet();
}

function petDatabase(): Promise<IDBDatabase> {
  return new Promise((resolve, reject) => {
    const request = indexedDB.open("codex-claude-info", 1);
    request.onupgradeneeded = () => request.result.createObjectStore("settings");
    request.onsuccess = () => resolve(request.result);
    request.onerror = () => reject(request.error);
  });
}

async function readStoredPet(): Promise<void> {
  const database = await petDatabase();
  const stored = await new Promise<{ blob: Blob; name: string } | undefined>((resolve, reject) => {
    const request = database.transaction("settings").objectStore("settings").get("pet");
    request.onsuccess = () => resolve(request.result);
    request.onerror = () => reject(request.error);
  });
  if (stored?.blob) {
    customPetUrl = URL.createObjectURL(stored.blob);
    customPetName = stored.name || "사용자 펫";
  }
}

async function savePet(file: File): Promise<void> {
  if (!file.type.startsWith("image/") || file.size > 15 * 1024 * 1024) {
    window.alert("PNG, JPG, WebP, GIF 이미지를 15MB 이하로 선택해 주세요.");
    return;
  }
  const displayName = file.name.replace(/\.[^.]+$/, "") || "사용자 펫";
  const database = await petDatabase();
  await new Promise<void>((resolve, reject) => {
    const request = database.transaction("settings", "readwrite")
      .objectStore("settings").put({ blob: file, name: displayName }, "pet");
    request.onsuccess = () => resolve();
    request.onerror = () => reject(request.error);
  });
  if (customPetUrl) URL.revokeObjectURL(customPetUrl);
  customPetUrl = URL.createObjectURL(file);
  customPetName = displayName;
  render();
}

async function resetPet(): Promise<void> {
  const database = await petDatabase();
  await new Promise<void>((resolve, reject) => {
    const request = database.transaction("settings", "readwrite").objectStore("settings").delete("pet");
    request.onsuccess = () => resolve();
    request.onerror = () => reject(request.error);
  });
  if (customPetUrl) URL.revokeObjectURL(customPetUrl);
  customPetUrl = undefined;
  customPetName = "짱구 코디";
  render();
}

async function refresh(): Promise<void> {
  if (!isTauri) {
    data = {
      codex: {
        connected: true,
        source: "Codex app-server · POC 미리보기",
        model: "gpt-5.6-codex",
        effort: "High",
        task: "Windows POC 작업 중",
        yesterday_tokens: 128_400,
        week_tokens: 759_400,
        limits: [
          { title: "단기 사용량", used_percent: 26, window_minutes: 300, resets_at: Date.now() / 1000 + 8_200 }
        ]
      },
      claude: {
        connected: true,
        source: "Claude Desktop · POC 미리보기",
        model: "Claude Fable 5",
        effort: "Xhigh",
        task: "최근 세션 감지됨",
        yesterday_tokens: 93_200,
        week_tokens: 481_000,
        limits: [
          { title: "5시간 사용량", used_percent: 55, window_minutes: 300 },
          { title: "7일 사용량", used_percent: 11, window_minutes: 10_080 }
        ]
      },
      updated_at: Date.now() / 1000
    };
    loading = false;
    render();
    return;
  }
  loading = true;
  render();
  try {
    data = await invoke<Dashboard>("get_dashboard");
  } catch (error) {
    data[selected].error = String(error);
  } finally {
    loading = false;
    render();
  }
}

render();
readStoredPet().then(render).catch(() => undefined);
refresh();
setInterval(refresh, 30_000);
