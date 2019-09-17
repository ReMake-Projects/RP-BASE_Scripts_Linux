#! /bin/bash

# TekLabs TekBase
# Copyright since 2005 TekLab
# Christian Frankenstein
# Website: teklab.de
#          teklab.net

VAR_A=$1
VAR_B=$2
VAR_C=$3

checkpasswd() {
    export VAR_C
    originalpw=$(grep -w "root" /etc/shadow | cut -d: -f2)
    export algo=$(echo $originalpw | cut -d'$' -f2)
    export salt=$(echo $originalpw | cut -d'$' -f3)
    genpw=$(perl -le 'print crypt("$ENV{VAR_C}","\$$ENV{algo}\$$ENV{salt}\$")')
    if [ "$genpw" == "$originalpw" ]; then
	echo "error";
    else
	echo "ok";
    fi
}


if [ "$VAR_A" = "cpu" ]; then
    tekresult=""
    cpucores=$(grep ^processor /proc/cpuinfo | wc -l)
    for (( i=0; $i < $cpucores; i++ )); do
	totallast[$i]=0; busylast[$i]=0
    done

    counter=0
    while [ $counter != 2 ]; do
	for (( i=0; $i < $cpucores; i++ )); do
	    cpudata=$(grep ^"cpu"$i /proc/stat)
	    busyticks=$(echo $cpudata | awk -F' ' '{printf "%.0f",$2+$3+$4+$7+$8-$BL}')
	    totalticks=$(echo $cpudata | awk -F' ' '{printf "%.0f",$2+$3+$4+$5+$6+$7+$8}')

	    let "busy_1000=1000*($busyticks-${busylast[$i]})/($totalticks-${totallast[$i]})"
	    let "busyfull=$busy_1000/10"
	    let "busytick=$busy_1000"

	    if [ $counter = 1 ]; then
		tekresult="$tekresult$i,$busyfull.$busytick{TEKEND}"
	    fi

	    totallast[$i]=$totalticks
	    busylast[$i]=$busyticks
	done
	let "counter=$counter+1"
	sleep 0.5
    done
    cpuname=$(grep 'model name' /proc/cpuinfo | sed -e 's/model name.*: //'| uniq -u)
    echo "$cpuname{TEKEND}$tekresult"
fi

if [ "$VAR_A" = "dedicated" ]; then
    memall=$(free -k | grep -i "mem" | awk '{print $2,$3,$4,$6,$7}')
    memtotal=$(echo "$memall" | awk '{print $1}')
    memfree=$(echo "$memall" | awk '{print $3+$5+$6}')
    memtype=$(dmidecode --type memory | grep -i "Type:\|Size:\|Speed:" | grep -v "Error\|Clock" | sed 's/Type: /"type":"/g' | sed 's/Speed: /"speed":"/g' | sed 's/Size: /"size":"/g' | sed 's/^[ \t]*//' | sed 's/$/"/g' | tr "\n" ",")
    hddlist=$(lsblk | grep [hsm] | grep -v "─" | awk '{print $1}')
    hdds=""
    for hdd in $hddlist
    do
	hddtyp=$(cat /sys/block/$hdd/queue/rotational | sed 's/0/ssd/g' | sed 's/1/hdd/g')
	hddtotal=$(lsblk | grep -i "$hdd" | awk 'NR==1{print $4}')
	hddswap=$(lsblk | grep -i "$hdd" | grep -i "SWAP" | awk '{print $4}')
	hddstat=$(smartctl -H /dev/$hdd | grep -i "overall-health" | awk -F': ' '{print $2}')
	hddtemp=$(hddtemp -u C /dev/$hdd | sed 's/°C//g' | awk -v smart="$hddstat" -v htyp="$hddtyp" -v htotal="$hddtotal" -v hswap="$hddswap" -F': ' '{print "{\"hdd\":\""$1"\",\"name\":\""$2"\",\"type\":\""htyp"\",\"total\":\""htotal"\",\"swap\":\""hswap"\",\"temp\":\""$3"\",\"status\":\""smart"\",\"parts\":["}')
	if [ "$hddtemp" = "" ]; then
	    hddtemp="{\"hdd\":\"$hdd\",\"name\":\"$hdd\",\"type\":\"$hddtyp\",\"total\":\"$hddtotal\",\"swap\":\"$hddswap\",\"temp\":\"-\",\"status\":\"$hddstat\",\"parts\":["
	fi
	hddpart=$(df -k | grep -i "/dev/$hdd" | grep -v "tmpfs" | awk '{print "{\"part\":\""$1"\",\"total\":\""$2"\",\"used\":\""$3"\",\"mount\":\""$6"\"}"}' | tr "\n" ",")
	if [ "$hdds" = "" ]; then
	    hdds="$hdds$hddtemp$hddpart]}"
	else
	    hdds="$hdds,$hddtemp$hddpart]}"
	fi
    done
    timeformat=$(mpstat | grep -i PM)
    if [ "$timeformat" = "" ]; then
        cpuperc=$(mpstat -P ALL | awk 'NR>4 {print "\""$2+1"\":\""$3"\""}' | tr "\n" ",")
    else
        cpuperc=$(mpstat -P ALL | awk 'NR>4 {print "\""$3+1"\":\""$4"\""}' | tr "\n" ",")
    fi
#   cpuname=`cat /proc/cpuinfo | grep -i 'model name' | sed -e 's/model name.*: //' | uniq -u`
    cpuinfo=$(dmidecode --type processor | grep -i "Version:\|Max Speed:" | sed 's/Version: /"name":"/g' | sed 's/Max Speed: /"speed":"/g' | sed 's/^[ \t]*//' | sed 's/[[:space:]]\+/ /g' | sed 's/$/"/g' | tr "\n" "," | sed 's/ "/"/g')
    if [ "$cpuinfo" = "" ]; then
        cpuinfo=$(grep -m 1 -i "model name" /proc/cpuinfo | sed 's/model name/"name":"/g' | sed 's/^[ \t]*//' | sed 's/[[:space:]]:[[:space:]]\+//g' | sed 's/$/"/g' | tr "\n" ",")
    fi
    cputemp=`sensors | grep -i "temp1:" | awk '{print "\"temp\":\""$2"\",\"critic\":\""$5"\""}' | sed 's/[+°C)]//g' | uniq -u`
#    traffic=`vnstat | grep -i "$VAR_B" | sed 's/KiB/KB/g' | sed 's/MiB/MB/g' | sed 's/GiB/GB/g' | awk '{print "$3,$4"$6,$7}'`
    ipv4=$(ifconfig | grep -v "127.0.0.1" | awk -v i=1 '/inet addr/{print "\""i++"\":\""substr($2,6)"\""}' | tr "\n" ",")
    trafficdays=$(vnstat -i $(ip route | column -t | awk '{print $5}' | head -n1) -d | grep -v "eth\|day\|estimated\|-" | sed 's/KiB/KB/g' | sed 's/MiB/MB/g' | sed 's/GiB/GB/g' | sed 's/TiB/TB/g' | sed 's/\//./g' | awk 'NR>2 {print "{\"date\":\""$1"\",\"rx\":\""$2,$3"\",\"tx\":\""$5,$6"\"}"}' | tr "\n" ",")
    trafficmonths=$(vnstat -i $(ip route | column -t | awk '{print $5}' | head -n1) -m | grep -v "eth\|month\|estimated\|-" | sed 's/KiB/KB/g' | sed 's/MiB/MB/g' | sed 's/GiB/GB/g' | sed 's/TiB/TB/g' | sed 's/\//./g' | awk 'NR>2 {print "{\"date\":\""$1,$2"\",\"rx\":\""$3,$4"\",\"tx\":\""$6,$7"\"}"}' | tr "\n" ",")
    echo "{\"cpu\":{$cpuinfo\"cores\":{$cpuperc},$cputemp},\"ram\":{$memtype\"total\":\"$memtotal\",\"free\":\"$memfree\"},\"hdds\":[$hdds],\"ipv4\":{$ipv4},\"traffic\":{\"daily\":[$trafficdays],\"monthly\":[$trafficmonths]},\"rootpw\":\"$(checkpasswd)\"}" | sed 's/,}/}/g' | sed 's/,]/]/g'
fi


exit 0
