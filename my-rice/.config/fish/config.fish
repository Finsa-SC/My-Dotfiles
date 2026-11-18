
if status is-interactive
    set -g fish_greeting ""

    # ── Fastfetch
    fastfetch

    # ── Direnv + Zoxide
    command -v direnv &>/dev/null && direnv hook fish | source
    command -v zoxide &>/dev/null && zoxide init fish --cmd cd | source

    # ── Better ls
    alias ls='eza --icons --group-directories-first -1'

    # ── Abbreviations
    abbr lg 'lazygit'
    abbr gd 'git diff'
    abbr ga 'git add .'
    abbr gc 'git commit -am "'
    abbr gl 'git log'
    abbr gs 'git status'
    abbr gst 'git stash'
    abbr gsp 'git stash pop'
    abbr gp 'git push'
    abbr gpl 'git pull'
    abbr gsw 'git switch'
    abbr gsm 'git switch main'
    abbr gb 'git branch'
    abbr gbd 'git branch -d'
    abbr gco 'git checkout'
    abbr gsh 'git show'
    abbr l 'ls'
    abbr ll 'ls -l'
    abbr la 'ls -a'
    abbr lla 'ls -la'

    # ── Auto-load pentest session vars
    if test -d $XDG_RUNTIME_DIR/pentest-session
        for f in $XDG_RUNTIME_DIR/pentest-session/*
            set -gx (basename $f) (cat $f)
        end
    end

    # ── Command execution metrics
    function __command_metrics --on-event fish_postexec
        set -l exit_code $status
        set -l duration $CMD_DURATION

        echo ""

        # Format execution time
        if test $duration -lt 1000
            set duration "$duration ms"
        else
            set duration (math -s2 "$duration / 1000")" s"
        end

        # Colors
        set -l green (set_color 7577f5 --bold)
        set -l red (set_color fc9b99 --bold)
        set -l muted (set_color baa7a6)
        set -l reset (set_color normal)

        # Exit status color
        if test $exit_code -eq 0
            set status_color $green
            set symbol "✔︎"
        else
            set status_color $red
            set symbol "〤"
        end

        # Single line: "  󰔛 58 ms  󰄬 0"
        echo -n "  $muted󰔛 $duration  "
        echo -n "$status_color $symbol $exit_code"
        echo $reset
    end

    # ── Prompt (Wonder Acute Palette Integration)
    function fish_prompt
        # ── Setup Left Palette
        set arrow_start (set_color 7577f5 normal)
        set green (set_color --background 7577f5 1a1a2e)
        set arrow_g (set_color 7577f5 --background f4f3f0)
        set white (set_color --background f4f3f0 1a1a2e)
        set arrow_w (set_color f4f3f0 --background ebaac0)
        set orange (set_color --background ebaac0 1a1a2e)
        set arrow_o (set_color ebaac0 normal)

        # ── Setup Right Palette
        set text_blue (set_color --background 72636b fc9b99 --bold)
        set arrow_b (set_color 72636b normal)
        set text_git (set_color --background ebaac0 1a1a2e --bold)
        set arrow_g_rev (set_color ebaac0 72636b)
        set arrow_o_rev (set_color ebaac0 normal)
        set reset (set_color normal)

        # ── Git Metrics Palette
        set m_green (set_color 7577f5 --bold)
        set m_red (set_color fc9b99 --bold)
        set m_muted (set_color baa7a6)

        # 1. LEFT ANCHOR
        echo -n ╭$arrow_start""$green"  Silen"$arrow_g""$white"ce"$arrow_w""$orange"Suzuka"$arrow_o""$reset

        # 2. PATH
        set -l max_path_len 20
        set -l current_path (prompt_pwd)

        if test (string length $current_path) -gt $max_path_len
            set current_path "..."(string sub -s -$max_path_len $current_path)
        end

        set current_path " "$current_path" "

        # 3. GIT INFORMATION
        set -l git_info ""
        set -l git_raw_len 0
        set -l floating_metrics ""
        set -l metrics_raw_len 0

        if git rev-parse --is-inside-work-tree &>/dev/null 2>&1
            # A. Branch
            set -l branch (git branch --show-current 2>/dev/null)

            set git_info $arrow_o_rev""$text_git"  $branch "$arrow_g_rev""
            set git_raw_len (math (string length "  $branch ") + 2)

            # B. Changed lines
            set -l git_stat (git diff --numstat 2>/dev/null | awk '{add+=$1; del+=$2} END {print add, del}')
            set -l added (echo $git_stat | awk '{print $1}')
            set -l deleted (echo $git_stat | awk '{print $2}')

            test -z "$added"; and set added 0
            test -z "$deleted"; and set deleted 0

            # C. Ahead / Behind
            set -l ahead 0
            set -l behind 0

            set -l upstream (git rev-parse --abbrev-ref --symbolic-full-name @{u} 2>/dev/null)

            if test -n "$upstream"
                set -l rev_list (git rev-list --left-right --count HEAD...@{u} 2>/dev/null)
                set ahead (echo $rev_list | awk '{print $1}')
                set behind (echo $rev_list | awk '{print $2}')
            end

            test -z "$ahead"; and set ahead 0
            test -z "$behind"; and set behind 0

            # D. Floating Metrics
            set -l parts

            if test "$ahead" -gt 0
                set -a parts $m_green"▲"$ahead
            end

            if test "$behind" -gt 0
                set -a parts $m_red"▼"$behind
            end

            if test "$added" -gt 0
                set -a parts $m_green"🢅"$added
            end

            if test "$deleted" -gt 0
                set -a parts $m_red"🢆"$deleted
            end

            if test (count $parts) -gt 0
                set floating_metrics (string join " " $parts)$reset

                set -l raw_parts

                if test "$ahead" -gt 0
                    set -a raw_parts "🡽"$ahead
                end

                if test "$behind" -gt 0
                    set -a raw_parts "🡾"$behind
                end

                if test "$added" -gt 0
                    set -a raw_parts "⁺"$added
                end

                if test "$deleted" -gt 0
                    set -a raw_parts "⁻"$deleted
                end

                set metrics_raw_len (string length (string join " " $raw_parts))
            end
        end

        # 4. RIGHT PROMPT CALCULATION
        set -l path_raw_len (string length $current_path)
        set -l right_prompt $git_info$text_blue$current_path$arrow_b""$reset
        set -l total_right_len (math $git_raw_len + $path_raw_len + 1)

        # 5. FLOATING GIT METRICS
        if test $metrics_raw_len -gt 0
            echo -n (tput sc)
            echo -n (tput cuu1) (tput hpa $COLUMNS) (tput cub (math $total_right_len - 1)) $floating_metrics
            echo -n (tput rc)
        end

        # 6. RIGHT DOCKING
        echo -n -s (tput hpa $COLUMNS) (tput cub $total_right_len) $right_prompt

        # 7. INPUT AREA
        echo ""
        set input_arrow (set_color 7577f5 --bold)
        echo -n ╰$input_arrow"﴿ "$reset
    end

    # ── Right Prompt
    function fish_right_prompt
    end

    # ── Sandbox Notify Watcher
    if not pgrep -f "sandbox-notify-watcher" >/dev/null
        fish -c '
            set queue /tmp/sandbox-notify.queue
            touch $queue
            tail -f $queue | while read line
                set parts (string split "|" $line)
                notify-send --urgency=$parts[1] --icon=$parts[2] --app-name="sandbox" --expire-time=8000 $parts[3] $parts[4]
            end
        ' &
    end
end

# ── Environment Export
function env-export
    for line in (string match -r '^[^#][^=]*=.*$' < .env)
        set -l key (string split -m1 '=' $line)[1]
        set -l value (string split -m1 '=' $line)[2]
        set -gx $key $value
    end
end

# ── Aliases
alias subv='uv run app/main.py'
alias c='clear && printf "\033[3J"'
alias search='pacman -Ss'
alias arch-cleaner='arch-cleaner.sh'
alias nullthis='nullthis.sh'
alias mksh='~/.config/scripts/mksh.sh'
alias wifi='nmgui'
alias dc='docker compose exec'

# ── PATH
set -gx PATH $HOME/.local/bin $PATH

