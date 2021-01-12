#!/bin/bash
#
# Добавляет в cron задачи для pomodoro
# 

x=<< END
SHELL=/bin/bash

0,30  * * * *    notify-send "Задача 25 мин"
25,55 * * * *    notify-send "Перерыв 5 мин"
END

case $1 in
start) echo "$x" | crontab -l ;;
stop) echo -n | crontab -l ;;
status) 
	if [ "`crintab -l`" == "" ]; then
		echo "Помодоро остановлен"
	elif ; then
		echo "Осталось минут задачи"
	else
		echo "Осталось минут перерыва"
	fi
	;;
*) echo "
Добавляет в cron задачи для pomodoro

	$ ./pomodoro.sh [start|stop|status]
";;
esac

