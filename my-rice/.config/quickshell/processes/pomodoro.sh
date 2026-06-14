#!/bin/bash

LOG_FILE="/tmp/pomodoro_time.log"
SAFETY_PIN="/tmp/disable_pomodoro"

if [[ -f $SAFETY_PIN ]]; then
	exit 0
fi

if [[ -f $LOG_FILE ]]; then
	CURRENT_TIME=$(date +%s)
	SLEEP_TIME=$(cat "$LOG_FILE")
	SLEEP_DURATION=$(( CURRENT_TIME - SLEEP_TIME ))
	
	if [[ $SLEEP_DURATION -lt 300 ]]; then
		sleep 20
		
		if [[ -f $SAFETY_PIN ]]; then
			exit 0
		fi

		sudo systemctl suspend
		exit 0
	else
		rm -f "$LOG_FILE"
	fi
fi

sleep 20
notify-send "Starting pomodoro" "Happy work master" -a "Nino"
sleep 1200
notify-send "Rest time master" "Computer will be suspend in 5 minutes" -a "Nino"
sleep 300
notify-send "It's time to rest" "Happy rest, master!" -a "Nino"
sleep 10

date +%s > $LOG_FILE

sudo systemctl suspend
