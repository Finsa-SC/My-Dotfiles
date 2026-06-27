set -g __cmd_start_time 0
set -g __cmd_origin_win "0"

function __preexec_notify --on-event fish_preexec
    if test "$__cmd_start_time" = "0"
        set -g __cmd_start_time (date +%s)
        if command -q hyprctl
            set -g __cmd_origin_win (hyprctl activewindow -j 2>/dev/null | jq -r '.address // "0"' 2>/dev/null)
        else
            set -g __cmd_origin_win "0"
        end
    end
end

function __postexec_notify --on-event fish_postexec
    set -l exit_code $status
    set -l cmd $argv[1]

    if test -z "(string trim -- "$cmd")"; or test "$__cmd_start_time" = "0"
        return
    end

    set -l now (date +%s)
    set -l duration (math $now - $__cmd_start_time)
    set -l threshold 180

    # Cek window
    set -l current_win "0"
    if command -q hyprctl
        set -l addr (hyprctl activewindow -j 2>/dev/null | jq -r '.address // "0"' 2>/dev/null)
        if test -n "$addr"; and test "$addr" != "null"; and test "$addr" != ""
            set current_win "$addr"
        end
    end

    set -l win_changed false
    if test "$__cmd_origin_win" != "0"; and test "$current_win" != "0"
        if test "$__cmd_origin_win" != "$current_win"
            set win_changed true
        end
    end

    # Filter: beda WS → langsung kirim, bypass semua filter
    if test "$win_changed" = false
        set -l first_word (string split -m 1 " " $cmd)[1]
        set -l interactive_cmds vim nvim nano htop btop less more fzf ssh sudo man cd ls clear git c l ll la lla gc ga gp gpl gsw gsm echo cat mkdir rm cp mv ps grep kill sleep mpv
        if contains -- $first_word $interactive_cmds; and test $duration -lt $threshold
            set -g __cmd_start_time 0
            return
        end
        if test $duration -lt $threshold
            set -g __cmd_start_time 0
            return
        end
    end

    # Format waktu
    set -l duration_str ""
    if test $duration -ge 60
        set -l mins (math -s0 $duration / 60)
        set -l secs (math $duration % 60)
        set duration_str "$mins""m $secs""s"
    else
        set duration_str "$duration""s"
    end

    # Title & urgency
    set -l app_label "System"
    set -l title "Task Completed Successfully"
    set -l urgency "normal"
    if test $exit_code -ne 0
        set title "Task Execution Failed (exit: $exit_code)"
        set urgency "critical"
    else if test $duration -ge $threshold
        set title "Long Task Finished"
    end

    set -l clean_cmd (string sub -l 30 $cmd)
    if test (string length $cmd) -gt 30
        set clean_cmd "$clean_cmd..."
    end

    set -l body "⏱ $duration_str  •  \$ $clean_cmd"
    if test "$win_changed" = true
        set body "$body  •  (background)"
    end

    set -g __cmd_start_time 0

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
