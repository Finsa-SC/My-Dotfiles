#!/bin/bash
orphans=$(pacman -Qdtq)

if [[ -z "${orphans}" ]]; then
    notify-send "No unused packages found" "Canceled" -a "arch-cleaner"
    exit 0
else
    sudo pacman -Rns --noconfirm ${orphans}
    if (( $? == 0 )); then
        notify-send "Successfully cleaned up" "Success" -a "arch-cleaner"
    else
        notify-send "Failed to clean up" "Failed" -a "arch-cleaner"
    fi
fi
