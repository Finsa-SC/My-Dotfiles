#!/bin/bash

CURRENT_BAT=$(cat /sys/class/power_supply/BAT0/capacity)
#CURRENT_BAT=14
PREVIOUS_BAT=$CURRENT_BAT

while true; do
  STATUS_BAT=$(cat /sys/class/power_supply/BAT0/status)
  
  # Battery in charging
  if [[ $STATUS_BAT == "Charging" ]]; then
    if (( CURRENT_BAT >= 100 )); then
      notify-send "Battery fully charged" "Battery has reached 100%. Please unplug the charger" -a "System"
    elif (( CURRENT_BAT >= 95 )); then
      notify-send "Battery almost full" "Current charge is 95%. Consider unplugging" -a "System"
    fi
    sleep 120 #Add long delay cause in charging mode
    continue
  fi

  # Battery not in charging
  if (( CURRENT_BAT <= 5 )); then #Check if battery under 5% and send notify
    notify-send "Emergency Low Power" "System will hibernate in 2 minutes. Plug in charge to abort" -a "System" -u critical
    sleep 120
    
    if [[ $STATUS_BAT != "Charging" ]]; then
      sudo systemctl hibernate
      exit 0
    else # Continue if battery is on charging
      continue
    fi

  elif (( CURRENT_BAT <= 10 )); then
    notify-send "Your Battery is Very Low" "Plug in your device now, $CURRENT_BAT% remaining" -a "System" -u critical

  elif (( CURRENT_BAT <= 20 )); then
    notify-send "Low Battery" "$CURRENT_BAT% battery remaining" -a "System"
  fi

  # Delay and looping until next check session
  while true; do
    CURRENT_BAT=$(cat /sys/class/power_supply/BAT0/capacity)

    if (( PREVIOUS_BAT != CURRENT_BAT )); then
      PREVIOUS_BAT=$CURRENT_BAT
      break
      
    else # Delay if battery is the same as previous
      sleep 20
      
    fi
  done
done
