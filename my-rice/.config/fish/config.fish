if status is-interactive
    fastfetch
    set -g fish_greeting ""
    # Direnv + Zoxide
    command -v direnv &> /dev/null && direnv hook fish | source
    command -v zoxide &> /dev/null && zoxide init fish --cmd cd | source

    # Better ls
    alias ls='eza --icons --group-directories-first -1'

    # Abbrs
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

    # ── Prompt (Silence Suzuka Core Anchor + Floating Metrics)
    function fish_prompt
        # Setup Warna Kiri (Fixed Anchor)
        set arrow_start (set_color 00b386 normal)
        set green (set_color --background 00b386 1a1a2e)
        set arrow_g (set_color 00b386 --background e8e8e8)
        set white (set_color --background e8e8e8 1a1a2e)
        set arrow_w (set_color e8e8e8 --background e8750a)
        set orange (set_color --background e8750a ffffff)
        set arrow_o (set_color e8750a normal)
        
        # Setup Warna Kanan (Dock Kanan)
        set text_blue (set_color --background 2c2e3e 00b386 --bold)    # Path
        set arrow_b (set_color 2c2e3e normal)                          # Arrow tutup path
        set text_git (set_color --background e8750a 1a1a2e --bold)     # Git
        set arrow_g_rev (set_color e8750a 2c2e3e)                      # Transisi Git -> Path
        set arrow_o_rev (set_color e8750a normal)                      # Arrow buka git
        set reset (set_color normal)

        # Warna untuk Git Metrics Melayang
        set m_green (set_color 00b386 --bold)
        set m_red (set_color e8750a --bold)
        set m_muted (set_color 6e6e8e)

        # 1. CETAK BLOK KIRI (Anchor Utama)
        echo -n ╭$arrow_start""$green"  Silen"$arrow_g""$white"ce"$arrow_w""$orange"Suzuka"$arrow_o""$reset

        # 2. PROSES DATA PATH KANAN
        set -l max_path_len 20
        set -l current_path (prompt_pwd)
        if test (string length $current_path) -gt $max_path_len
            set current_path "..."(string sub -s -$max_path_len $current_path)
        end
        set current_path " "$current_path" "

        # 3. PROSES DATA GIT DAN METRICS
        set -l git_info ""
        set -l git_raw_len 0
        set -l floating_metrics ""
        set -l metrics_raw_len 0

        if git rev-parse --is-inside-work-tree &>/dev/null 2>&1
            # A. Ambil nama branch
            set -l branch (git branch --show-current 2>/dev/null)
            set git_info $arrow_o_rev""$text_git"  $branch "$arrow_g_rev""
            set git_raw_len (math (string length "  $branch ") + 2)

            # B. Ambil Git Metrics (Lines Added / Deleted)
            set -l git_stat (git diff --numstat 2>/dev/null | awk '{add+=$1; del+=$2} END {print add, del}')
            set -l added (echo $git_stat | awk '{print $1}')
            set -l deleted (echo $git_stat | awk '{print $2}')
            [ -z "$added" ]; and set added 0
            [ -z "$deleted" ]; and set deleted 0

            # C. Ambil Git Ahead / Behind (Sync Status dengan Remote Repo)
            set -l ahead 0
            set -l behind 0
            set -l upstream (git rev-parse --abbrev-ref --substring-index @{u} 2>/dev/null)
            if test -n "$upstream"
                set -l rev_list (git rev-list --left-right --count HEAD...@{u} 2>/dev/null)
                set ahead (echo $rev_list | awk '{print $1}')
                set behind (echo $rev_list | awk '{print $2}')
            end

            # D. Format Tampilan Floating Metrics (Hanya muncul jika ada angka > 0)
            set -l parts
            if test "$ahead" -gt 0; set -a parts $m_green"▲"$ahead; end
            if test "$behind" -gt 0; set -a parts $m_red"▼"$behind; end
            if test "$added" -gt 0; set -a parts $m_green"🢅"$added; end
            if test "$deleted" -gt 0; set -a parts $m_red"🢆"$deleted; end

            if test (count $parts) -gt 0
                set floating_metrics (string join " " $parts)$reset
                # Hitung panjang teks mentah untuk kalkulasi posisi tput
                set -l raw_parts
                if test "$ahead" -gt 0; set -a raw_parts "🡽"$ahead; end
                if test "$behind" -gt 0; set -a raw_parts "🡾"$behind; end
                if test "$added" -gt 0; set -a raw_parts "⁺"$added; end
                if test "$deleted" -gt 0; set -a raw_parts "⁻"$deleted; end
                set metrics_raw_len (string length (string join " " $raw_parts))
            end
        end
        
        # Gabungkan blok utama kanan
        set -l path_raw_len (string length $current_path)
        set -l right_prompt $git_info$text_blue$current_path$arrow_b""$reset
        set -l total_right_len (math $git_raw_len + $path_raw_len + 1)

        # 4. CETAK FLOATING METRICS DI ATAS BLOK KANAN (JIKA ADA DATA)
        if test $metrics_raw_len -gt 0
            echo -n (tput sc) # Save posisi kursor saat ini
            # Lompat ke 1 baris di atas, geser ke posisi kanan sejajar dengan blok Git
            echo -n (tput cuu1) (tput hpa $COLUMNS) (tput cub (math $total_right_len - 1)) $floating_metrics
            echo -n (tput rc) # Kembalikan kursor ke baris prompt utama
        end

        # 5. DOCKING BLOK UTAMA KANAN
        echo -n -s (tput hpa $COLUMNS) (tput cub $total_right_len) $right_prompt

        # 6. PINDAH BARIS KE INPUT AREA
        echo ""
        set input_arrow (set_color 00b386 --bold)
        echo -n ╰$input_arrow"﴿ "$reset
    end

    function fish_right_prompt
    end
end

abbr tests '/usr/local/bin/test.sh'
alias subv='uv run app/main.py'
alias c='clear'
alias search='pacman -Ss'
alias arch-cleaner='arch-cleaner.sh'
alias nullthis='nullthis.sh'
