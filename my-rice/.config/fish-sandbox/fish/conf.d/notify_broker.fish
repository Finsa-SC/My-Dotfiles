set -g __cmd_start_time 0
set -g __cmd_origin_ws ""

function __preexec_notify --on-event fish_preexec
    set -g __cmd_start_time (date +%s)
    if command -q hyprctl
        set -g __cmd_origin_ws (hyprctl activewindow -j 2>/dev/null | jq -r '.workspace.id' 2>/dev/null)
    else
        set -g __cmd_origin_ws "0"
    end
end

function __postexec_notify --on-event fish_postexec
    set -l exit_code $status
    set -l cmd $argv[1]
    set -l now (date +%s)
    set -l duration (math $now - $__cmd_start_time)
    set -l threshold 180

    set -l interactive_cmds "vim" "nvim" "nano" "htop" "btop" "less" "more" "fzf" "ssh"
    for skip in $interactive_cmds
        if string match -q -- "$skip*" "$cmd"
            return
        end
    end

    if command -q hyprctl
        set -l current_ws (hyprctl activewindow -j 2>/dev/null | jq -r '.workspace.id' 2>/dev/null)
    else
        set -l current_ws "0"
    end

    set -l ws_changed false
    if test "$__cmd_origin_ws" != "$current_ws"
        set ws_changed true
    end

    if test $duration -lt $threshold; and test $ws_changed = false
        return
    end

    set -l icon "terminal"
    set -l urgency "normal"
    set -l mins (math -s0 $duration / 60)
    set -l secs (math $duration % 60)
    set -l duration_str "$mins""m $secs""s"

    if test $exit_code -ne 0
        set icon "dialog-error"
        set urgency "critical"
    end

    set -l ws_info ""
    if test $ws_changed = true
        set ws_info " | ws$__cmd_origin_ws → ws$current_ws"
    end

    set -l title "Command Finished (exit: $exit_code)"
    set -l body "⏱ $duration_str | \$ $cmd$ws_info"

    if set -q SANDBOX
        echo "$urgency|$icon|$title|$body" >> /tmp/sandbox-notify.queue
    else
        notify-send \
            --urgency=$urgency \
            --icon=$icon \
            --app-name="fish" \
            --expire-time=8000 \
            "$title" "$body"
    end
end