set -g __cmd_start_time 0
set -g __cmd_origin_win "0"

function __preexec_notify --on-event fish_preexec
    set -g __cmd_start_time (date +%s)
    if command -q hyprctl
        set -g __cmd_origin_win (hyprctl activewindow -j 2>/dev/null | jq -r '.address // "0"' 2>/dev/null)
    else
        set -g __cmd_origin_win "0"
    end
end

function __postexec_notify --on-event fish_postexec
    # ── VALIDASI EMERGENSI 1: Jika preexec tidak jalan (start time masih 0) atau command kosong, KELUAR!
    if test "$__cmd_start_time" = "0"; or test -z (string trim -- "$argv[1]")
        return
    end

    set -l exit_code $status
    set -l cmd $argv[1]
    set -l now (date +%s)
    set -l duration (math $now - $__cmd_start_time)
    set -l threshold 180 # 3 Menit

    # RESET START TIME LANGSUNG: Biar pemicu ganda akibat alias/fungsi tidak lolos di eksekusi kedua
    set -g __cmd_start_time 0

    # Ambil kata pertama dari command (Membaca alias/abbr mentah jika ada)
    set -l first_word (string split -m 1 " " $cmd)[1]

    # Daftar perintah interaktif & harian yang wajib diabaikan
    set -l interactive_cmds vim nvim nano htop btop less more fzf ssh sudo man cd ls clear git c l ll la lla gc ga gp gpl gsw gsm echo cat mkdir rm cp mv ps grep kill
    if contains -- $first_word $interactive_cmds
        # Perintah harian di atas hanya boleh kirim notif KALAU jalannya lama (> 3 menit)
        if test $duration -lt $threshold
            return
        end
    end

    # Cek window aktif saat ini
    set -l current_win "0"
    if command -q hyprctl
        set -l addr (hyprctl activewindow -j 2>/dev/null | jq -r '.address // "0"' 2>/dev/null)
        if test -n "$addr"; and test "$addr" != "null"
            set current_win "$addr"
        end
    end

    # Deteksi perubahan window
    set -l win_changed false
    if test "$__cmd_origin_win" != "0"; and test "$current_win" != "0"
        if test "$__cmd_origin_win" != "$current_win"
            set win_changed true
        end
    end

    # ── VALIDASI EMERGENSI 2: Jika selesai < 3 menit DAN kamu TIDAK pindah window, JANGAN KIRIM NOTIF!
    if test $duration -lt $threshold; and test "$win_changed" = false
        return
    end

    # ── Menghias Format Waktu ──
    set -l duration_str ""
    if test $duration -ge 60
        set -l mins (math -s0 $duration / 60)
        set -l secs (math $duration % 60)
        set duration_str "$mins""m $secs""s"
    else
        set duration_str "$duration""s"
    end

    # ── Pengelompokan Urgency & Title untuk QML kamu ──
    set -l app_label "System"
    set -l title "Task Completed Successfully"
    set -l urgency "normal"

    if test $exit_code -ne 0
        set title "Task Execution Failed"
        set urgency "critical"
        set app_label "System"
    else if test $duration -ge $threshold
        set title "Long Task Finished"
        set app_label "fish"
    end

    # Potong command panjang
    set -l clean_cmd (string sub -l 30 $cmd)
    if test (string length $cmd) -gt 30
        set clean_cmd "$clean_cmd..."
    end

    # Menghias Konten Body
    set -l body "⏱ $duration_str  •  \$ $clean_cmd"
    if test "$win_changed" = true
        set body "$body (Sent to background)"
    end

    # ── Eksekusi Pengiriman ──
    if set -q SANDBOX
        echo "$urgency|terminal|$title|$body" >> /tmp/sandbox-notify.queue
    else
        notify-send \
            --urgency=$urgency \
            --app-name="$app_label" \
            --expire-time=6000 \
            "$title" "$body"
    end
end