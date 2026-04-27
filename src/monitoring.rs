// DeskRu device-monitoring client.
//
// Spawns a background thread that polls the public monitoring-status endpoint
// every 60s; when the org-admin enabled monitoring for *this* device, sends
// telemetry to /api/client/telemetry every 30s. Static hardware info is
// attached once an hour. The whole loop is opt-in per-device (server-side
// flag `peer.monitoring_enabled`) — without that flag, server returns 403
// fail-silent and the client just keeps polling for status changes.
//
// On poll/send network errors we keep going (next attempt in 30s) — never
// crash the process. The HTTP path uses common::http_request_sync, which
// already tunnels through the configured proxy when set.
//
// The Bearer access_token is re-read from LocalConfig at every send, so
// re-login after the loop has started is picked up automatically (no need
// to restart the loop; logout simply makes telemetry pauses until next login).

use hbb_common::config::LocalConfig;
use hbb_common::log;
use serde::Serialize;
use std::sync::Mutex;
use std::time::{Duration, Instant};
use sysinfo::{Disks, Networks, System};

const POLL_STATUS_INTERVAL_SECS: u64 = 60;
const SEND_TELEMETRY_INTERVAL_SECS: u64 = 30;
const STATIC_INFO_REFRESH_SECS: u64 = 3600;

// Idempotent start: a second start_telemetry_loop call won't spawn a duplicate
// thread (e.g. when Flutter re-fires the start hook after re-login).
static MONITORING_STARTED: Mutex<bool> = Mutex::new(false);

#[derive(Serialize)]
pub struct TelemetryStatic {
    pub cpu_model: String,
    pub cpu_cores: u32,
    pub cpu_threads: u32,
    pub ram_total_bytes: u64,
    pub disks: Vec<DiskInfo>,
    pub gpu: String,
    pub os_detail: String,
    pub kernel: String,
    pub hostname: String,
}

#[derive(Serialize)]
pub struct DiskInfo {
    pub model: String,
    pub size: u64,
    #[serde(rename = "type")]
    pub type_: String,
}

#[derive(Serialize)]
pub struct TelemetryCurrent {
    pub cpu_usage_percent: f32,
    pub ram_used_bytes: u64,
    pub ram_total_bytes: u64,
    pub disk_used_bytes: u64,
    pub disk_total_bytes: u64,
    pub uptime_secs: u64,
    pub battery_percent: Option<i32>,
    pub battery_charging: Option<bool>,
    pub net_rx_bytes: u64,
    pub net_tx_bytes: u64,
}

pub fn collect_static() -> TelemetryStatic {
    let mut sys = System::new();
    sys.refresh_cpu_all();
    sys.refresh_memory();

    let cpu_model = sys
        .cpus()
        .first()
        .map(|c| c.brand().to_string())
        .unwrap_or_default();
    let cpu_threads = sys.cpus().len() as u32;
    let cpu_cores = sys
        .physical_core_count()
        .unwrap_or(cpu_threads as usize) as u32;
    let ram_total_bytes = sys.total_memory();

    let disks = Disks::new_with_refreshed_list();
    let disk_infos: Vec<DiskInfo> = disks
        .iter()
        .map(|d| DiskInfo {
            model: d.name().to_string_lossy().to_string(),
            size: d.total_space(),
            type_: format!("{:?}", d.kind()),
        })
        .collect();

    let os_detail = format!(
        "{} {}",
        System::name().unwrap_or_default(),
        System::os_version().unwrap_or_default()
    )
    .trim()
    .to_string();
    let kernel = System::kernel_version().unwrap_or_default();
    let hostname = System::host_name().unwrap_or_default();

    TelemetryStatic {
        cpu_model,
        cpu_cores,
        cpu_threads,
        ram_total_bytes,
        disks: disk_infos,
        gpu: collect_gpu_name(),
        os_detail,
        kernel,
        hostname,
    }
}

#[cfg(target_os = "macos")]
fn collect_gpu_name() -> String {
    // Best-effort: parse `system_profiler SPDisplaysDataType` for the first
    // chipset name. Returns "" on any failure — never panics.
    let output = match std::process::Command::new("system_profiler")
        .arg("SPDisplaysDataType")
        .output()
    {
        Ok(o) => o,
        Err(_) => return String::new(),
    };
    let text = String::from_utf8_lossy(&output.stdout);
    for line in text.lines() {
        let trimmed = line.trim();
        if let Some(rest) = trimmed.strip_prefix("Chipset Model:") {
            return rest.trim().to_string();
        }
    }
    String::new()
}

#[cfg(target_os = "linux")]
fn collect_gpu_name() -> String {
    // Try `lspci -mm` and grep VGA / 3D / Display lines. First match wins.
    let output = match std::process::Command::new("lspci").arg("-mm").output() {
        Ok(o) => o,
        Err(_) => return String::new(),
    };
    let text = String::from_utf8_lossy(&output.stdout);
    for line in text.lines() {
        let class_lower = line.to_lowercase();
        if class_lower.contains("vga") || class_lower.contains("3d") || class_lower.contains("display") {
            // Lines look like: 00:02.0 "VGA compatible controller" "Intel" "UHD Graphics" -ra1 ...
            // Pick the 4th quoted field — the device name.
            let parts: Vec<&str> = line.split('"').collect();
            if parts.len() >= 8 {
                return format!("{} {}", parts[5].trim(), parts[7].trim())
                    .trim()
                    .to_string();
            }
        }
    }
    String::new()
}

#[cfg(target_os = "windows")]
fn collect_gpu_name() -> String {
    // wmic is deprecated but still ships on Win10/11. PowerShell fallback for
    // hosts where wmic was removed. Returns "" on any failure.
    if let Ok(out) = std::process::Command::new("wmic")
        .args(["path", "win32_VideoController", "get", "name", "/value"])
        .output()
    {
        let text = String::from_utf8_lossy(&out.stdout);
        for line in text.lines() {
            if let Some(rest) = line.trim().strip_prefix("Name=") {
                if !rest.is_empty() {
                    return rest.to_string();
                }
            }
        }
    }
    if let Ok(out) = std::process::Command::new("powershell")
        .args([
            "-NoProfile",
            "-Command",
            "(Get-CimInstance Win32_VideoController | Select-Object -First 1).Name",
        ])
        .output()
    {
        let text = String::from_utf8_lossy(&out.stdout).trim().to_string();
        if !text.is_empty() {
            return text;
        }
    }
    String::new()
}

pub fn collect_current() -> TelemetryCurrent {
    let mut sys = System::new();
    // CPU usage requires two refresh calls separated by at least
    // MINIMUM_CPU_UPDATE_INTERVAL (~200ms). Without the gap, global_cpu_usage
    // returns 0 on the first sample.
    sys.refresh_cpu_usage();
    std::thread::sleep(sysinfo::MINIMUM_CPU_UPDATE_INTERVAL);
    sys.refresh_cpu_usage();
    sys.refresh_memory();

    let cpu_usage_percent = sys.global_cpu_usage();
    let ram_used_bytes = sys.used_memory();
    let ram_total_bytes = sys.total_memory();

    // System disk = the largest mounted volume by total size. Heuristic, but
    // matches user expectation on every desktop OS: the boot disk is the
    // largest physical drive in 99% of cases.
    let disks = Disks::new_with_refreshed_list();
    let (disk_used, disk_total) = disks
        .iter()
        .max_by_key(|d| d.total_space())
        .map(|d| (d.total_space().saturating_sub(d.available_space()), d.total_space()))
        .unwrap_or((0, 0));

    let uptime_secs = System::uptime();

    // Network: sum across all non-loopback interfaces. Cumulative bytes since
    // the OS booted — server diff'es two consecutive samples to derive rate.
    let networks = Networks::new_with_refreshed_list();
    let (rx, tx) = networks
        .iter()
        .filter(|(name, _)| !is_loopback(name))
        .fold((0u64, 0u64), |(r, t), (_, n)| {
            (
                r.saturating_add(n.total_received()),
                t.saturating_add(n.total_transmitted()),
            )
        });

    let (battery_percent, battery_charging) = battery_info();

    TelemetryCurrent {
        cpu_usage_percent,
        ram_used_bytes,
        ram_total_bytes,
        disk_used_bytes: disk_used,
        disk_total_bytes: disk_total,
        uptime_secs,
        battery_percent,
        battery_charging,
        net_rx_bytes: rx,
        net_tx_bytes: tx,
    }
}

fn is_loopback(name: &str) -> bool {
    let n = name.to_lowercase();
    n == "lo" || n == "lo0" || n.starts_with("loopback")
}

fn battery_info() -> (Option<i32>, Option<bool>) {
    // starship-battery is best-effort. Desktops without batteries return an
    // empty iterator, not an error — both branches return (None, None).
    let manager = match starship_battery::Manager::new() {
        Ok(m) => m,
        Err(_) => return (None, None),
    };
    let batteries = match manager.batteries() {
        Ok(b) => b,
        Err(_) => return (None, None),
    };
    for b in batteries.flatten() {
        let pct = (b.state_of_charge().value * 100.0) as i32;
        let charging = matches!(
            b.state(),
            starship_battery::State::Charging | starship_battery::State::Full
        );
        return (Some(pct), Some(charging));
    }
    (None, None)
}

pub fn start_telemetry_loop(device_id: String) {
    let mut started = MONITORING_STARTED.lock().unwrap();
    if *started {
        log::info!("[deskru-monitoring] loop already running, skip");
        return;
    }
    *started = true;
    drop(started);

    std::thread::spawn(move || telemetry_loop(device_id));
}

fn telemetry_loop(device_id: String) {
    log::info!(
        "[deskru-monitoring] loop started, device_id={}",
        device_id
    );

    let api = crate::ui_interface::get_api_server();
    if api.is_empty() {
        log::warn!("[deskru-monitoring] no API server configured, abort");
        // Reset the started flag so a future call (after API is set) succeeds.
        *MONITORING_STARTED.lock().unwrap() = false;
        return;
    }
    let api = api.trim_end_matches('/').to_string();

    // Force the first status check and static-send by setting "last" timers far
    // in the past.
    let mut last_status_check = Instant::now() - Duration::from_secs(POLL_STATUS_INTERVAL_SECS + 1);
    let mut last_static_sent = Instant::now() - Duration::from_secs(STATIC_INFO_REFRESH_SECS + 1);
    let mut enabled_cached = false;

    loop {
        if last_status_check.elapsed() >= Duration::from_secs(POLL_STATUS_INTERVAL_SECS) {
            enabled_cached = poll_status(&api, &device_id);
            last_status_check = Instant::now();
        }

        if enabled_cached {
            let static_due =
                last_static_sent.elapsed() >= Duration::from_secs(STATIC_INFO_REFRESH_SECS);
            // Static-due is only consumed when we actually send (token present).
            // If we skipped due to logout, retry static on the next tick.
            if send_telemetry(&api, &device_id, static_due) && static_due {
                last_static_sent = Instant::now();
            }
        }

        std::thread::sleep(Duration::from_secs(SEND_TELEMETRY_INTERVAL_SECS));
    }
}

fn poll_status(api: &str, device_id: &str) -> bool {
    let url = format!(
        "{}/api/public/monitoring-status?device_id={}",
        api, device_id
    );
    let header = r#"{"Content-Type":"application/json"}"#.to_string();

    let raw = match crate::common::http_request_sync(url, "GET".to_string(), None, header) {
        Ok(r) => r,
        Err(e) => {
            log::warn!("[deskru-monitoring] poll_status network: {}", e);
            return false;
        }
    };

    let envelope: serde_json::Value = match serde_json::from_str(&raw) {
        Ok(v) => v,
        Err(_) => return false,
    };
    let status = envelope
        .get("status_code")
        .and_then(|v| v.as_u64())
        .unwrap_or(0);
    if !(200..300).contains(&status) {
        return false;
    }
    let body_str = envelope
        .get("body")
        .and_then(|v| v.as_str())
        .unwrap_or("");
    let body: serde_json::Value = match serde_json::from_str(body_str) {
        Ok(v) => v,
        Err(_) => return false,
    };
    body.get("enabled")
        .and_then(|v| v.as_bool())
        .unwrap_or(false)
}

// Returns true if a request was attempted (token present), false if skipped
// because the user is currently logged out. The caller uses this to decide
// whether to advance the static-info timer.
fn send_telemetry(api: &str, device_id: &str, include_static: bool) -> bool {
    let access_token = LocalConfig::get_option("access_token");
    if access_token.is_empty() {
        log::debug!("[deskru-monitoring] no access_token (logged out), skip send");
        return false;
    }

    let current = collect_current();
    let mut payload = serde_json::json!({
        "device_id": device_id,
        "current": current,
    });
    if include_static {
        payload["static"] = serde_json::to_value(collect_static()).unwrap_or_default();
    }

    let url = format!("{}/api/client/telemetry", api);
    let header = format!(
        r#"{{"Content-Type":"application/json","Authorization":"Bearer {}"}}"#,
        access_token
    );

    match crate::common::http_request_sync(
        url,
        "POST".to_string(),
        Some(payload.to_string()),
        header,
    ) {
        Ok(_) => {
            log::debug!(
                "[deskru-monitoring] telemetry sent (static={})",
                include_static
            );
        }
        Err(e) => {
            log::warn!("[deskru-monitoring] send failed: {}", e);
        }
    }
    true
}
