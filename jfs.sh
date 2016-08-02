#!/bin/bash

# Script for administering the JSano Fan Server
# by Chris Kreidler 

# exits the script if you're in a tmux session
intmux() {
    if { [ "$TERM" = "screen" ] && [ -n "$TMUX" ]; } then
        echo "This script is not meant to be used inside TMUX. Please detach and try again."
        exit
    fi
}
intmux

# detects if the vanilla server is running
isrunning() {
    ps ax | grep -v grep | grep -v tmux | grep "minecraft_server.jar" > /dev/null
    return $?
}

# saves the vanilla server to disk
save() {
    tmux -q send -t 0 "save-all" C-m
}

# creates a backup of the vanilla world folder
# keeps bihourly backups for two days
# keeps daily backups for 10 days
# keeps weekly backups for 10 weeks
# keeps monthly backups forever
backup() {
    if [ $1 == "bihourly" ]; then
        tmux -q send -t 0 "save-all" C-m
        sleep 1
        tmux -q send -t 0 "save-off" C-m
        FILENAME="vanilla-backup_$(date +%F_%H-%M)_bihourly.tar.gz"
        cd /home/jfs/vanilla/
        tar czf /home/jfs/vanilla/backup/$FILENAME world
        tmux -q send -t 0 "save-on" C-m
        cd /home/jfs/vanilla/backup
        /bin/ls -t | grep "bihourly" | awk 'NR>22' | xargs rm
#       lftp -c "open -u ********,******** dedibackup-dc2.online.net; mirror -Re . /jfs"
    elif [ $1 == "daily" ]; then
        d=$(date +%d)
        u=$(date +%u)
        if [ $u -eq "1" ] && [ $d -lt "8" ]; then
            tmux -q send -t 0 "save-all" C-m
            sleep 1
            tmux -q send -t 0 "save-off" C-m
            FILENAME="vanilla-backup_$(date +%F_%H-%M)_monthly.tar.gz"
            cd /home/jfs/vanilla/
            tar czf /home/jfs/vanilla/backup/$FILENAME world
            tmux -q send -t 0 "save-on" C-m
        elif [ $u -eq "1" ]; then
            tmux -q send -t 0 "save-all" C-m
            sleep 1
            tmux -q send -t 0 "save-off" C-m
            FILENAME="vanilla-backup_$(date +%F_%H-%M)_weekly.tar.gz"
            cd /home/jfs/vanilla/
            tar czf /home/jfs/vanilla/backup/$FILENAME world
            tmux -q send -t 0 "save-on" C-m
            cd /home/jfs/vanilla/backup
            /bin/ls -t | grep "weekly" | awk 'NR>10' | xargs rm
#           lftp -c "open -u ********,******** dedibackup-dc2.online.net; mirror -Re . /jfs"
        else
            tmux -q send -t 0 "save-all" C-m
            sleep 1
            tmux -q send -t 0 "save-off" C-m
            FILENAME="vanilla-backup_$(date +%F_%H-%M)_daily.tar.gz"
            cd /home/jfs/vanilla/
            tar czf /home/jfs/vanilla/backup/$FILENAME world
            tmux -q send -t 0 "save-on" C-m
            cd /home/jfs/vanilla/backup
            /bin/ls -t | grep "daily" | awk 'NR>10' | xargs rm
#           lftp -c "open -u ********,******** dedibackup-dc2.online.net; mirror -Re . /jfs"
        fi
    else
        echo "Incorrect usage"
    fi
}

# updates a file showing how long ago the overviewer was updated
# file contents are displayed under the map on the website
overviewertime() {
    h=$(date +%H)
    if [ $h -eq "0" ]; then
        echo Last updated less than an hour ago > /var/www/html/updated.txt
    elif [ $h -eq "1" ]; then
        echo Last updated 1 hour ago > /var/www/html/updated.txt
    else
        echo Last updated $(date +%-H) hours ago > /var/www/html/updated.txt
    fi
}

# activated by swatch when '.tps' is detected in the vanilla log file
# runs a debug start/stop on the server console and displays the result back in chat
tps() {
    tmux -q send -t 0 "debug start" C-m
    sleep 1
    tmux -q send -t 0 "debug stop" C-m
    sleep .1
    ticks=`tac vanilla/logs/latest.log | grep -m1 ticks | sed -r 's/.*(.{10})/\1/' | sed 's/(//' | sed 's/)//' | sed 's/]//'`
    output="say $ticks per second"
    tmux -q send -t 0 "$output" C-m
}

# runs a function depending on your command argument(s)
case $1 in
    save)
        save
        ;;
    backup)
        backup $2
        ;;
    overviewertime)
        overviewertime
        ;;
    tps)
        tps
esac
