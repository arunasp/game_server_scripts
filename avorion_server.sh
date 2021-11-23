#!/bin/bash

ADMINSTEAM64ID=01234567890123456
STEAMDIR=/home/avorion/Steam
STEAMCMDDIR=/home/avorion/steamcmd
SERVERDIR="/home/avorion/server"
DATADIR="/home/avorion/avorion_data"
GALAXY="Galaxy"
MAXPLAYERS=16
SERVERIPADRESS=0.0.0.0
SERVERARGS="--galaxy-name ${GALAXY} --admin ${ADMINSTEAM64ID} --datapath "${DATADIR}" --max-players ${MAXPLAYERS} --same-start-sector 1 --play-tutorial 1 --difficulty 0 --alive-sectors-per-player 7 --stderr-to-log 1 --stdout-to-log 1 --immediate-writeout 1 -t warning  -t exception --multiplayer 1 --ip ${SERVERIPADRESS} --listed 1 --port 27000 --query-port 27003 --steam-master-port 27020 --steam-master-port 27021 --use-steam-networking 1 --force-steam-networking 0"

SERVERSTARTCOMMAND="$SERVERDIR/bin/AvorionServer"
SERVERPROCESS=$(basename "${SERVERSTARTCOMMAND}")
APPID=565060

export templdpath=$LD_LIBRARY_PATH
export LD_LIBRARY_PATH=$SERVERDIR/linux64:$LD_LIBRARY_PATH

function CheckForUpdates()
{
    while sleep 1
    do
    cd "$STEAMCMD"
    if [ ! -f "$SERVERDIR/Logs/updateinprogress.dat" ]
    then
        touch "$SERVERDIR/Logs/updateinprogress.dat"
        rm -fr $STEAMDIR/appcache
        $STEAMCMDDIR/steamcmd.sh +login anonymous +app_info_update 1 +app_info_print "${APPID}"  +quit | grep -EA 1000 "^\s+\"branches\"$" | grep -EA 5 "^\s+\"public\"$" | grep -m 1 -EB 10 "^\s+}$" | grep -E "^\s+\"buildid\"\s+" | tr '[:blank:]"' ' ' | tr -s ' ' | cut -d\  -f3 > "$SERVERDIR/Logs/latestavailableupdate.txt"
        #sleep 1m
        LATESTUPDATE=$(cat "$SERVERDIR/Logs/latestavailableupdate.txt")
        INSTALLEDUPDATE=$(cat "$SERVERDIR/Logs/latestinstalledupdate.txt")

        if [ "$LATESTUPDATE" != "$INSTALLEDUPDATE" ] && [ "$LATESTUPDATE" != "" ] && [ "$INSTALLEDUPDATE" != "" ]
        then
        	echo "/say New update available, server is restarting in 15 minutes!" >> "${DATADIR}/${GALAXY}/commands.txt"
        	sleep 10m
        	echo "/say New update available, server is restarting in 5 minutes! >> "${DATADIR}/${GALAXY}/commands.txt"
        	sleep 5m
        	echo "/say New update available, server is restarting in 1 minute, the update will take up to few minutes! >> "${DATADIR}/${GALAXY}/commands.txt"
        	sleep 1m
        	echo "/say The server is restarting NOW, the update will take up to few minutes! >> "${DATADIR}/${GALAXY}/commands.txt"
        	echo "/save >> "${DATADIR}/${GALAXY}/commands.txt"
        	sleep 30
        	cnt="3"
        	while [ $(expr $(date +%s` - `stat -L --format %Y ""${DATADIR}"/index")) -lt 120 -a ! -z "$(pidof '${SERVERPROCESS}')" -a "$cnt" -gt 0 ]
        	do
        	    sleep 1m
        	    let cnt=$cnt-1
        	done
        	echo "/stop" >> "${DATADIR}/${GALAXY}/commands.txt"
        	sleep 10
        	[ ! -z "$(pidof "${SERVERPROCESS}")" ] && kill $(pidof "${SERVERPROCESS}")
        	sleep 3
        	[ ! -z "$(pidof "${SERVERPROCESS}")" ] && kill -9 $(pidof "${SERVERPROCESS}")
        	echo "$(date) Update – $(echo $INSTALLEDUPDATE) to $(echo $LATESTUPDATE)" | tee -a "$SERVERDIR"/Logs/Updatelog.txt
        	rm -f "$SERVERDIR/Logs/updateinprogress.dat"
        	$STEAMCMDDIR/steamcmd.sh +force_install_dir "$SERVERDIR" +login anonymous +app_update ${APPID} -validate +quit
        	$STEAMCMDDIR/steamcmd.sh +login anonymous +app_info_update 1 +app_info_print "${APPID}" +quit | grep -EA 1000 "^\s+\"branches\"$" | grep -EA 5 "^\s+\"public\"$" | grep -m 1 -EB 10 "^\s+}$" | grep -E "^\s+\"buildid\"\s+" | tr '[:blank:]"' ' ' | tr -s ' ' | cut -d\  -f3 > "$SERVERDIR/Logs/latestinstalledupdate.txt"
        	rm -f "$SERVERDIR/Logs/updateinprogress.dat"
        else
            rm -f "$SERVERDIR/Logs/updateinprogress.dat"
        fi
    fi
    sleep 10m
    done
}


cd "$STEAMCMD"

[ -z "$(pidof "${SERVERPROCESS}")" ] && rm -f "$SERVERDIR/Logs/updateinprogress.dat"
$STEAMCMDDIR/steamcmd.sh +login anonymous +app_info_update 1 +app_info_print "${APPID}" +quit | grep -EA 1000 "^\s+\"branches\"$" | grep -EA 5 "^\s+\"public\"$" | grep -m 1 -EB 10 "^\s+}$" | grep -E "^\s+\"buildid\"\s+" | tr '[:blank:]"' ' ' | tr -s ' ' | cut -d\  -f3 > "$SERVERDIR/Logs/latestavailableupdate.txt"
[ ! -f "$SERVERDIR/Logs/latestinstalledupdate.txt" -o -z "$SERVERDIR/Logs/latestinstalledupdate.txt" ] && $STEAMCMDDIR/steamcmd.sh  +login anonymous +app_info_update 1 +app_info_print "${APPID}" +quit | grep -EA 1000 "^\s+\"branches\"$" | grep -EA 5 "^\s+\"public\"$" | grep -m 1 -EB 10 "^\s+}$" | grep -E "^\s+\"buildid\"\s+" | tr '[:blank:]"' ' ' | tr -s ' ' | cut -d\  -f3 > "$SERVERDIR"/Logs/latestinstalledupdate.txt

[ $# -eq 1 ] && CheckForUpdates 2>&1
[ $# -lt 1 ] && nohup $0 updates | tee -a "$SERVERDIR"/Logs/startup.log 2>&1&

mkdir -p "$SERVERDIR"/Logs

[ $# -lt 1 ] && \
while sleep 10
do
    if [ -z "$(pidof avorion_server.x86_64)" -a -z "$(pidof steamcmd)" -a ! -f "$SERVERDIR/Logs/updateinprogress.dat" ]
    then
	echo "----------------- $(date) -----------------" >> "$SERVERDIR"/Logs/startup.log
	cd "$SERVERDIR"
	"$SERVERSTARTCOMMAND" $SERVERARGS 2>&1 | tee -a "$SERVERDIR"/Logs/startup.log
    fi
sleep 50
done

export LD_LIBRARY_PATH=$templdpath
