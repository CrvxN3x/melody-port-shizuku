#!/system/bin/sh
# melody-port.sh — Port of ionuttbara/melody_android tweaks for use via Shizuku (no root).
# Run INSIDE Shizuku:  sh rish  ->  sh /sdcard/melody-port.sh
# Source of commands: https://github.com/ionuttbara/melody_android (README)

set -eu

STAMP="$(date +%Y%m%d-%H%M%S)"
BASE="/sdcard/melody-port"; mkdir -p "$BASE"
PRE_G="$BASE/pre-global-$STAMP.txt";  POST_G="$BASE/post-global-$STAMP.txt";  BKP_G="$BASE/backup-global.txt"
PRE_S="$BASE/pre-system-$STAMP.txt";  POST_S="$BASE/post-system-$STAMP.txt";  BKP_S="$BASE/backup-system.txt"
PRE_SEC="$BASE/pre-secure-$STAMP.txt";POST_SEC="$BASE/post-secure-$STAMP.txt";BKP_SEC="$BASE/backup-secure.txt"

say(){ printf "%s\n" "$*"; }
ok(){ say "[+] $*"; }
info(){ say "[*] $*"; }
err(){ say "[-] $*" >&2; }
need(){ command -v "$1" >/dev/null 2>&1 || { err "Missing '$1' — run inside Shizuku (sh rish)"; exit 1; }; }
need settings

# helpers
get(){ settings get "$1" "$2" 2>/dev/null || true; }
put(){ settings put "$1" "$2" "$3" >/dev/null 2>&1 || true; }
del(){ settings delete "$1" "$2" >/dev/null 2>&1 || true; }
snap(){ settings list "$1" | sed 's/[[:space:]]*$//' | sort >"$2" || true; }
diffit(){ pre="$1"; post="$2"; title="$3"; say "==== changes ($title) ===="; if command -v diff >/dev/null 2>&1; then diff -u "$pre" "$post" || true; else say "-- added/changed:"; comm -13 "$pre" "$post" || true; say "-- removed:"; comm -23 "$pre" "$post" || true; fi; say "pre: $pre"; say "post: $post"; }
backup_tbl(){ tbl="$1"; dest="$2"; info "Backup $tbl -> $dest"; settings list "$tbl" >"$dest" || true; ok "Backup done."; }
restore_tbl(){ tbl="$1"; src="$2"; [ -f "$src" ] || { err "No backup: $src"; return 1; }; info "Restore $tbl from $src"; while IFS= read -r l; do k="${l%%=*}"; v="${l#*=}"; [ -n "$k" ] || continue; [ "$v" = "null" ] && settings delete "$tbl" "$k" || settings put "$tbl" "$k" "$v"; done <"$src"; ok "Restore done."; }

# ---------- Melody categories (ported) ----------
perf_ui(){
  # Disable blurs/animations; bump auto-bright adj; (optional) low refresh on some devices
  put global accessibility_reduce_transparency 1
  put global disable_window_blurs 1
  put global window_animation_scale 0.0
  put global transition_animation_scale 0.0
  put global animator_duration_scale 0.0
  put system screen_auto_brightness_adj 1.0
  # OPTIONAL (skip on 60 Hz panels): set low refresh
  put system peak_refresh_rate 48.0
  put system min_refresh_rate 1.0
  ok "Performance/UI tweaks applied."
}

networking(){
  # Network/UI scoring & offload/aggressive toggles from Melody
  put global network_recommendations_enabled 0
  put global network_scoring_ui_enabled 0
  put global tether_offload_disabled 0
  put global wifi_power_save 0
  put global enable_cellular_on_boot 1
  put global mobile_data_always_on 0
  put global ble_scan_always_enabled 0
  # Melody uses AdGuard DoT; you can change later in your other script
  put global private_dns_specifier family.adguard-dns.com
  # Optional/very device-specific: preferred network mode hack
  put global preferred_network_mode "9,9"
  ok "Networking tweaks applied."
}

power_management(){
  # Melody power policies; warning: can affect app background behavior
  put global sem_enhanced_cpu_responsiveness 0
  put global enhanced_processing 0
  put global app_standby_enabled 0
  put global adaptive_battery_management_enabled 0
  put global app_restriction_enabled true
  put system intelligent_sleep_mode 0
  put secure adaptive_sleep 0
  put global automatic_power_save_mode 0
  put global low_power 0
  put global dynamic_power_savings_enabled 0
  put global dynamic_power_savings_disable_threshold 20
  ok "Power management tweaks applied."
}

screensaver_off(){
  put secure screensaver_enabled 0
  put secure screensaver_activate_on_sleep 0
  put secure screensaver_activate_on_dock 0
  ok "Screensaver disabled."
}

press_delays(){
  put secure long_press_timeout 250
  put secure multi_press_timeout 250
  ok "Press delay sped up."
}

call_features(){
  put system call_extra_volume 1
  put system call_noise_reduction 1
  put system call_answer_vib 0
  put system call_end_vib 0
  put global swipe_to_call_message 0
  ok "Call feature tweaks applied."
}

device_name(){
  printf "Enter new device name: "
  read -r name
  [ -z "$name" ] && { err "Empty."; return 1; }
  put secure bluetooth_name "$name"
  put global device_name "$name"
  put global synced_account_name "$name"
  ok "Device name set -> $name"
}

sys_sounds_vibes(){
  put system navigation_gestures_vibrate 0
  put system lockscreen_sounds_enabled 0
  put system camera_feedback_vibrate 0
  put system sound_effects_enabled 0
  put system sync_vibration_with_ringtone 1
  put system sync_vibration_with_notification 1
  # Typos fixed from README: ensure both ringtone sync keys if present
  put system vibrate_when_ringing 0
  ok "System sounds/vibration tweaked."
}

disable_assistant_opa(){
  put secure systemui.google.opa_enabled 0
  ok "Hotword/OPA hook disabled (if present)."
}

motion_engine_off(){
  put system master_motion 0
  put system motion_engine 0
  put system air_motion_engine 0
  put system air_motion_wake_up 0
  put system intelligent_sleep_mode 0
  put secure adaptive_sleep 0
  ok "Motion/adaptive sleep disabled."
}

telemetry_speedups(){
  put global activity_starts_logging_enabled 0
  put secure send_action_app_error 0
  put global bixby_pregranted_permissions 0
  put system send_security_reports 0
  put system rakuten_denwa 0
  ok "Telemetry & app launch tweaks applied."
}

audio_quality(){
  put system tube_amp_effect 1
  put system k2hd_effect 1
  put system multicore_packet_scheduler 1
  ok "Audio/media tweaks applied."
}

kill_gos(){
  put secure game_auto_temperature_control 0
  settings cmd package clear --user 0 com.samsung.android.game.gos >/dev/null 2>&1 || true
  put secure gamesdk_version 0
  put secure game_home_enable 0
  put secure game_bixby_block 1
  ok "GOS mitigations applied."
}

block_updates(){
  put global galaxy_system_update_block 1
  ok "Galaxy system update policy block set."
}

oled_tweak(){
  put global burn_in_protection 1
  ok "OLED burn-in protection toggled."
}

touch_latency(){
  put secure tap_duration_threshold 0.0
  put secure touch_blocking_period 0.0
  ok "Touch latency thresholds set."
}

scan_off(){
  put system nearby_scanning_permission_allowed 0
  put system nearby_scanning_enabled 0
  put global ble_scan_always_enabled 0
  ok "Background scanning reduced."
}

hotword_off(){
  put global hotword_detection_enabled 0
  ok "Background hotword detection disabled."
}

samsung_cross_device(){
  put system mcf_continuity 0
  put system mcf_continuity_permission_denied 1
  put system mcf_permission_denied 1
  ok "Samsung cross-device continuity disabled."
}

ramplus_off(){
  put global ram_expand_size_list 0
  put global zram_enabled 0
  ok "RAM Plus/ZRAM disabled (reboot to take full effect)."
}

refresh_phone(){
  settings cmd package compile -m speed-profile -a >/dev/null 2>&1 || true
  settings cmd package bg-dexopt-job >/dev/null 2>&1 || true
  pm trim-caches 999999999999999999 >/dev/null 2>&1 || true
  ok "Refresh/compile/trim invoked."
}

dev_options_on(){
  put global development_settings_enabled 1
  ok "Developer Options enabled."
}

wifi_tweaks(){
  put global wifi_poor_connection_warning 0
  ok "Wi-Fi tweak applied."
}

# ---------- Menus ----------
apply_all(){
  perf_ui; networking; power_management; screensaver_off; press_delays; call_features
  sys_sounds_vibes; disable_assistant_opa; motion_engine_off; telemetry_speedups
  audio_quality; kill_gos; block_updates; oled_tweak; touch_latency; scan_off
  hotword_off; samsung_cross_device; ramplus_off; refresh_phone; dev_options_on; wifi_tweaks
}

snapshot_all_pre(){
  snap global "$PRE_G"; snap system "$PRE_S"; snap secure "$PRE_SEC"
}
snapshot_all_post(){
  snap global "$POST_G"; snap system "$POST_S"; snap secure "$POST_SEC"
  diffit "$PRE_G" "$POST_G" "global"
  diffit "$PRE_S" "$POST_S" "system"
  diffit "$PRE_SEC" "$POST_SEC" "secure"
}

while :; do
  say ""
  say "===== MELODY PORT (Shizuku) ====="
  say "Backups: 1) Backup all  2) Restore all"
  say "Perf/UI: 3) Apply performance/animation tweaks"
  say "Network: 4) Networking tweaks  5) Wi-Fi tweak"
  say "Power  : 6) Power mgmt tweaks  7) Screensaver OFF"
  say "Timing : 8) Faster press delays"
  say "Calls  : 9) Call features"
  say "Sounds : 10) System sounds/vibes"
  say "Hotword: 11) Disable OPA/Google hook  12) Disable hotword"
  say "Motion : 13) Disable motion/adaptive sleep"
  say "Telem  : 14) Telemetry/app-start tweaks"
  say "Audio  : 15) Audio quality/media"
  say "Games  : 16) Kill Samsung GOS (where present)"
  say "Updates: 17) Block Galaxy system updates"
  say "OLED   : 18) Burn-in protection"
  say "Touch  : 19) Touch latency thresholds"
  say "Scan   : 20) Reduce background scanning"
  say "Samsung: 21) Disable cross-device continuity"
  say "Memory : 22) Disable RAM Plus / ZRAM"
  say "Maint  : 23) Refresh/compile/trim"
  say "DevOpt : 24) Enable Developer Options"
  say "Name   : 25) Set device name"
  say "ALL    : 26) Apply ALL Melody tweaks"
  say "0) Exit"
  printf "Select: "; read -r a

  case "$a" in
    1) backup_tbl global "$BKP_G"; backup_tbl system "$BKP_S"; backup_tbl secure "$BKP_SEC" ;;
    2) restore_tbl global "$BKP_G"; restore_tbl system "$BKP_S"; restore_tbl secure "$BKP_SEC" ;;
    3) snapshot_all_pre; perf_ui; snapshot_all_post ;;
    4) snapshot_all_pre; networking; snapshot_all_post ;;
    5) snapshot_all_pre; wifi_tweaks; snapshot_all_post ;;
    6) snapshot_all_pre; power_management; snapshot_all_post ;;
    7) snapshot_all_pre; screensaver_off; snapshot_all_post ;;
    8) snapshot_all_pre; press_delays; snapshot_all_post ;;
    9) snapshot_all_pre; call_features; snapshot_all_post ;;
    10) snapshot_all_pre; sys_sounds_vibes; snapshot_all_post ;;
    11) snapshot_all_pre; disable_assistant_opa; snapshot_all_post ;;
    12) snapshot_all_pre; hotword_off; snapshot_all_post ;;
    13) snapshot_all_pre; motion_engine_off; snapshot_all_post ;;
    14) snapshot_all_pre; telemetry_speedups; snapshot_all_post ;;
    15) snapshot_all_pre; audio_quality; snapshot_all_post ;;
    16) snapshot_all_pre; kill_gos; snapshot_all_post ;;
    17) snapshot_all_pre; block_updates; snapshot_all_post ;;
    18) snapshot_all_pre; oled_tweak; snapshot_all_post ;;
    19) snapshot_all_pre; touch_latency; snapshot_all_post ;;
    20) snapshot_all_pre; scan_off; snapshot_all_post ;;
    21) snapshot_all_pre; samsung_cross_device; snapshot_all_post ;;
    22) snapshot_all_pre; ramplus_off; snapshot_all_post ;;
    23) snapshot_all_pre; refresh_phone; snapshot_all_post ;;
    24) snapshot_all_pre; dev_options_on; snapshot_all_post ;;
    25) snapshot_all_pre; device_name; snapshot_all_post ;;
    26) snapshot_all_pre; apply_all; snapshot_all_post ;;
    0) break ;;
    *) err "Invalid";;
  esac
done

ok "Done. Snapshots/backups in $BASE"

