if status is-interactive
    set -g fish_greeting ""

    # Direnv + Zoxide (Hanya jalan jika binary-nya di-expose ke sandbox)
    command -v direnv &> /dev/null && direnv hook fish | source
    command -v zoxide &> /dev/null && zoxide init fish --cmd cd | source

    # Better ls
    alias ls='eza --icons --group-directories-first -1'

    abbr l 'ls'
    abbr ll 'ls -l'
    abbr la 'ls -a'
    abbr lla 'ls -la'

    # ── Prompt Minimalist Sandbox Edition ──
    function fish_prompt
        # Palette Warna
        set -l blue (set_color --background 4fc3f7 0d0d1a)
        set -l cyan (set_color --background 00bcd4 0d0d1a)
        set -l bg_path (set_color --background 1a1a3e 4fc3f7 --bold)
        
        set -l arrow_b (set_color 4fc3f7 --background 00bcd4)
        set -l arrow_c (set_color 00bcd4 --background 1a1a3e)
        set -l arrow_end (set_color 1a1a3e normal)
        set -l reset (set_color normal)

        # Ambil path saat ini (versi pendek)
        set -l current_path (prompt_pwd)

        # Cetak Prompt Baris Pertama (Satu Baris Sederhana ke Kanan)
        echo -n ╭(set_color 4fc3f7)""$blue" 󰚌 SANDBOX "$arrow_b""$cyan" Suzuka "$arrow_c""$bg_path" $current_path "$arrow_end""$reset
        echo ""

        # Cetak Input Area (Baris Kedua)
        set -l input_arrow (set_color 00b386 --bold)
        echo -n ╰$input_arrow"﴿ "$reset
    end

    # Matikan prompt kanan bawaan fish biar ga numpuk
    function fish_right_prompt
    end
end

# ── Sandbox Shortcuts & Aliases ──
alias subv='uv run app/main.py'
alias c='clear && printf "\033[3J"'
alias search='pacman -Ss'
alias arch-cleaner='arch-cleaner.sh'
alias nullthis='nullthis.sh'