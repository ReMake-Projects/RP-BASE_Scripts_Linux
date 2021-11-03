#! /bin/bash

# TekLabs TekBase
# Copyright since 2005 TekLab
# Christian Frankenstein
# Website: teklab.de
#          teklab.net

VAR_A=$1
VAR_B=$2
VAR_C=$3
VAR_D=$4
VAR_E=$5
VAR_F=$6
VAR_G=$7
VAR_H=$8

if [ "$VAR_A" = "" ]; then
    ./tekbase
fi

LOGF=$(date +"%Y_%m")
LOGP=$(pwd)

if [ ! -d logs ]; then
    mkdir logs
    chmod 0777 logs
fi
if [ ! -d restart ]; then
    mkdir restart
    chmod 0777 restart
fi

if [ ! -f "logs/$LOGF.txt" ]; then
    echo "***TekBASE Script Log***" >> $LOGP/logs/$LOGF.txt
    chmod 0666 $LOGP/logs/$LOGF.txt
fi

#VAR_B USER
#VAR_C ID
#VAR_D PFAD
#VAR_E SHORTCUT
#VAR_F STARTBEFEHL
#VAR_G PIDFILE
#VAR_H PIDFILE 2

if [ "$VAR_A" = "start" ]; then
    if [ -f $LOGP/restart/$VAR_B-apps-$VAR_C ]; then
	rm $LOGP/restart/$VAR_B-apps-$VAR_C
    fi
    echo "#! /bin/bash" >> $LOGP/restart/$VAR_B-apps-$VAR_C
    if [ "$VAR_G" = "" ]; then
	echo "check=\`ps aux | grep -v grep | grep -i screen | grep -i \"apps$VAR_C-X\"\`" >> $LOGP/restart/$VAR_B-apps-$VAR_C
    else
	echo "if [ -f /home/$VAR_B/apps/$VAR_C/$VAR_G ]; then" >> $LOGP/restart/$VAR_B-apps-$VAR_C
	echo "check=\`ps -p \`cat /home/$VAR_B/apps/$VAR_C/$VAR_G\`\`" >> $LOGP/restart/$VAR_B-apps-$VAR_C
	echo "fi" >> $LOGP/restart/$VAR_B-apps-$VAR_C
    fi
    echo "if [ ! -n \"\$check\" ]; then" >> $LOGP/restart/$VAR_B-apps-$VAR_C
    echo "cd $LOGP;sudo -u $VAR_B ./apps 'start' '$VAR_B' '$VAR_C' '$VAR_D' '$VAR_E' '$VAR_F' '$VAR_G' '$VAR_H'" >> $LOGP/restart/$VAR_B-apps-$VAR_C
    echo "fi" >> $LOGP/restart/$VAR_B-apps-$VAR_C
    echo "exit 0" >> $LOGP/restart/$VAR_B-apps-$VAR_C
    chmod 0755 $LOGP/restart/$VAR_B-apps-$VAR_C

    cd /home/$VAR_B/apps/$VAR_D

    if [ "$VAR_G" = "" ]; then
	kill -9 $(ps aux | grep -v grep | grep -i screen | grep -i "apps$VAR_C-X" | awk '{print $2}')
	check=$(ps aux | grep -v grep | grep -i screen | grep -i "apps$VAR_C-X")
	screen -wipe
	if [ ! -n "$check" ]; then
	    screen -A -m -d -S apps$VAR_C-X $VAR_F
	    check=$(ps aux | grep -v grep | grep -i screen | grep -i "apps$VAR_C-X")
	    if [ -n "$check" ]; then
		echo "$(date) - App /home/$VAR_B/apps/$VAR_D was started ($VAR_F)" >> $LOGP/logs/$LOGF.txt
		echo "ID1"
	    else
		echo "$(date) - App /home/$VAR_B/apps/$VAR_D cant be started ($VAR_F)" >> $LOGP/logs/$LOGF.txt
		echo "ID2"
	    fi
	else
	    echo "$(date) - App /home/$VAR_B/apps/$VAR_D cant be stopped and restarted ($VAR_F)" >> $LOGP/logs/$LOGF.txt
	    echo "ID3"
	fi
    else
	if [ -f $VAR_G ]; then
	    check=$(ps -p $(cat $VAR_G) | grep -i "$VAR_H")
	    if [ -n "$check" ]; then
		kill -9 $(cat $VAR_G)
	    fi
	    check=$(ps -p $(cat $VAR_G) | grep -i "$VAR_H")
	    rm $VAR_G
	fi
	if [ ! -n "$check" ]; then
	    $VAR_F
	    sleep 2
	    if [ -f $VAR_G ]; then
		echo "$(date) - App /home/$VAR_B/apps/$VAR_D was started ($VAR_F)" >> $LOGP/logs/$LOGF.txt
		echo "ID1"
	    else
		echo "$(date) - App /home/$VAR_B/apps/$VAR_D cant be started ($VAR_F)" >> $LOGP/logs/$LOGF.txt
		echo "ID2"
	    fi
	else
	    echo "$(date) - App /home/$VAR_B/apps/$VAR_D cant be stopped and restarted ($VAR_F)" >> $LOGP/logs/$LOGF.txt
	    echo "ID3"
	fi
    fi
fi

if [ "$VAR_A" = "stop" ]; then
    if [ -f $LOGP/restart/$VAR_B-apps-$VAR_C ]; then
	rm $LOGP/restart/$VAR_B-apps-$VAR_C
    fi

    cd /home/$VAR_B/apps/$VAR_D

    if [ -f $LOGP/includes/stop/$VAR_E ]; then
	check=$($LOGP/includes/stop/$VAR_E "$VAR_B" "$VAR_C" "$VAR_D" "$VAR_E" "$VAR_F" "$VAR_G" "$VAR_H")
    else
        if [ "$VAR_G" = "" ]; then
	    kill -9 $(ps aux | grep -v grep | grep -i screen | grep -i "apps$VAR_C-X" | awk '{print $2}')
	    check=$(ps aux | grep -v grep | grep -i screen | grep -i "apps$VAR_C-X")
	    screen -wipe
        else
	    if [ -f $VAR_G ]; then
	        check=$(ps -p $(cat $VAR_G) | grep -i "$VAR_F")
	        if [ -n "$check" ]; then
	            kill -9 $(cat $VAR_G)
	        fi
	        check=$(ps -p $(cat $VAR_G) | grep -i "$VAR_F")
	        rm $VAR_G
            fi
        fi
    fi

    if [ ! -n "$check" ]; then
	echo "$(date) - App /home/$VAR_B/apps/$VAR_D was stopped" >> $LOGP/logs/$LOGF.txt
	echo "ID1"
    else
	echo "$(date) - App /home/$VAR_B/apps/$VAR_D cant be stopped" >> $LOGP/logs/$LOGF.txt
	echo "ID2"
    fi
fi

if [ "$VAR_A" = "content" ]; then
    cd /home/$VAR_B/apps/$VAR_D
    check=$(cat $VAR_E)
    for LINE in $check
    do
    	echo "$LINE%TEND%"
    done
fi

if [ "$VAR_A" = "update" ]; then
    check=$(ps aux | grep -v grep | grep -i screen | grep -i "$VAR_B$VAR_D-X")
    if [ ! -n "$check" ]; then
	screen -A -m -d -S b$VAR_B$VAR_D-X ./apps updaterun "$VAR_B" "$VAR_C" "$VAR_D" "$VAR_E"
    	echo "ID1"
    else
        echo "$(date) - Update of /home/$VAR_B/apps/$VAR_D cant be installed" >> $LOGP/logs/$LOGF.txt
        echo "ID2"
    fi
fi

if [ "$VAR_A" = "updaterun" ]; then
    sleep 2
    cd /home/$VAR_B/apps/$VAR_D
    comlist=$(echo "${VAR_E//;/$'\n'}")
    while read LINE
    do
    	if [ "$LINE" != "" ]; then
	    $LINE
	fi
    done < <(echo "$comlist")
    echo "$(date) - Update of /home/$VAR_B/apps/$VAR_D was installed" >> $LOGP/logs/$LOGF.txt
fi

if [ "$VAR_A" = "online" ]; then
    check=$(ps aux | grep -v grep | grep -i screen | grep -i "apps$VAR_C-X")
    if [ -n "$check" ]; then
	echo "ID1"
    else
	echo "ID2"
    fi
fi


if [ "$VAR_A" = "status" ]; then
    check=$(ps aux | grep -v grep | grep -i screen | grep -i "$VAR_E$VAR_B$VAR_D-X")
    if [ ! -n "$check" ]; then
	echo "ID1"
    else
	echo "ID2"
    fi
fi

exit 0
