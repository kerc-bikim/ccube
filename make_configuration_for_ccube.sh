#!/bin/bash
CPATH=/usr/bin
source ccube_info

connecting_dcube(){
	echo "Connecting Dcube"
	${CPATH}/ccube-hardware dcube status
	${CPATH}/ccube-hardware dcube switch config
	if [ $? != 0 ] ; then
		echo "	Error : D-cube connection"
		exit
	else
		echo "	D-Cube connection complete"
	fi
}

disconnecting_dcube(){
	echo "disconnecting Dcube"
	cd ~
	${CPATH}/ccube-hardware dcube status
	${CPATH}/ccube-hardware dcube switch measurement
	if [ $? != 0 ] ; then
		echo "	Error : D-cube connection"
		exit
	else
		echo "	D-Cube disconnection complete"
	fi
}
make_slarchive(){
	run_with_lock_PID=`pgrep run_with_lock`
	if [ ${run_with_lock_PID} ] ; then
		kill -9 ${run_with_lock_PID}
		sleep 0.5
	fi
	slarchive_PID=`pgrep slarchive`
	if [ ${slarchive_PID} ] ; then
		kill -9 ${slarchive_PID}
		sleep 0.5
	fi
	mkdir -p /opt/KIGAM/bin
	mkdir -p /opt/KIGAM/run
	mkdir -p /media/data/MSEED
	ln -s /usr/bin/slarchive /opt/KIGAM/bin/slarchive
	cp run_with_lock /opt/KIGAM/bin/
	purge_datafiles > /opt/KIGAM/bin/purge_datafiles.sh
	run_slarchive > /opt/KIGAM/bin/run_slarchive.sh 
	chmod +x  /opt/KIGAM/bin/purge_datafiles.sh /opt/KIGAM/bin/run_slarchive.sh  /opt/KIGAM/bin/run_with_lock
	chown -R ccube-admin:ccube-admin /opt/KIGAM	
	chown -R ccube-admin:ccube-admin /media/data/MSEED
	ccube-admin_crontab > /var/spool/cron/crontabs/ccube-admin
	chown ccube-admin:ccube-admin  /var/spool/cron/crontabs/ccube-admin
        chmod 600  /var/spool/cron/crontabs/ccube-admin

	root_crontab > /var/spool/cron/crontabs/root
	chown root:root  /var/spool/cron/crontabs/root
        chmod 600  /var/spool/cron/crontabs/root

	Check_Network_Alive > /opt/KIGAM/bin/Check_Network_Alive.sh
	chown root:root /opt/KIGAM/bin/Check_Network_Alive.sh
	chmod +x /opt/KIGAM/bin/Check_Network_Alive.sh
	systemctl restart cron
	
}

ccube-admin_crontab(){
printf " 
# DO NOT EDIT THIS FILE - edit the master and reinstall.
# (/tmp/crontab.UoztqX/crontab installed on Thu Apr  4 05:17:10 2019)
# (Cron version -- \$Id: crontab.c,v 2.13 1994/01/17 03:20:37 vixie Exp $)
# Edit this file to introduce tasks to be run by cron.
#
# Each task to run has to be defined through a single line
# indicating with different fields when the task will be run
# and what command to run for the task
#
# To define the time you can provide concrete values for
# minute (m), hour (h), day of month (dom), month (mon),
# and day of week (dow) or use '*' in these fields (for 'any').#
# Notice that tasks will be started based on the cron's system
# daemon's notion of time and timezones.
#
# Output of the crontab jobs (including errors) is sent through
# email to the user the crontab file belongs to (unless redirected).
#
# For example, you can run a backup of all your user accounts
# at 5 a.m every week with:
# 0 5 * * 1 tar -zcf /var/backups/home.tgz /home/
#
# For more information see the manual pages of crontab(5) and cron(8)
#
# m h  dom mon dow   command
*/5 * * * * /opt/KIGAM/bin/run_slarchive.sh
0 1 * * * \"/opt/KIGAM/bin/purge_datafiles.sh /media/data/MSEED/ ${MSEED_SAVE}\"
"
}

root_crontab(){
printf " 
# DO NOT EDIT THIS FILE - edit the master and reinstall.
# (/tmp/crontab.UoztqX/crontab installed on Thu Apr  4 05:17:10 2019)
# (Cron version -- \$Id: crontab.c,v 2.13 1994/01/17 03:20:37 vixie Exp $)
# Edit this file to introduce tasks to be run by cron.
#
# Each task to run has to be defined through a single line
# indicating with different fields when the task will be run
# and what command to run for the task
#
# To define the time you can provide concrete values for
# minute (m), hour (h), day of month (dom), month (mon),
# and day of week (dow) or use '*' in these fields (for 'any').#
# Notice that tasks will be started based on the cron's system
# daemon's notion of time and timezones.
#
# Output of the crontab jobs (including errors) is sent through
# email to the user the crontab file belongs to (unless redirected).
#
# For example, you can run a backup of all your user accounts
# at 5 a.m every week with:
# 0 5 * * 1 tar -zcf /var/backups/home.tgz /home/
#
# For more information see the manual pages of crontab(5) and cron(8)
#
# m h  dom mon dow   command
*/10 * * * * /opt/KIGAM/bin/Check_Network_Alive.sh > /tmp/Check_Network_Alive.logs 2>&1
0 */1 * * * \"journalctl --vacuum-time=1seconds\"
"
}
purge_datafiles(){
printf "#!/bin/bash

usage(){
    echo \"usage> \$0 <directory> <keep_days>\"
    echo \"example_1> \$0 /data 500\"
    echo \"example_2> \$0 /data/log 30\"
}

ARCHIVE=\$1
KEEP=\$2

if [[ -z \$ARCHIVE ]]; then
    usage
    exit 1
fi
if [[ -z \$KEEP ]]; then
    usage
    exit 1
fi

#if [[ \$KEEP -lt 30 ]]; then
#    echo \"[WARNING] You can only purge data files older than 30 days.\"
#    echo \"  If you really want to purge data files younger than 30 days, run this command manaully.
#    echo   find \$ARCHIVE -type f -mtime +\$KEEP  -exec rm -f '{}' ;
#    exit 0
#fi

echo \"Finding old files...\"
echo \"find \$ARCHIVE -type f -mtime +\$KEEP\"
find \"\$ARCHIVE\" -type f -mtime +\"\$KEEP\"
echo \'Removing these files...'
find \"\$ARCHIVE\" -type f -mtime +\"\$KEEP\" -exec rm -f {} \\\\;
echo \"Done\"
"
}

Check_Network_Alive(){
printf "#!/bin/bash -x
echo \"Checking Time : `date`\"
restart_network(){
	echo \"restart network\"
	ccube-hardware mobile disable
	sleep 5
	ccube-hardware mobile enable
	/sbin/ifdown wwan0
	sleep 5
	/sbin/ifup wwan0
	sleep 5
}

restart_vpn(){
	echo \"restart openvpn\"
	systemctl restart openvpn
}

check_internet(){
	INT_IP=168.126.63.1
	ping -c 5 -W 2 \${INT_IP} 1>/dev/null
	INT_status=\$?
}

check_vpn(){
	VPN_IP=10.8.0.1
	ping -c 5 -W 2 \${VPN_IP} 1>/dev/null 
	VPN_status=\$?
}

check_internet
if [ \${INT_status} != 0 ] ; then
	restart_network		
fi

sleep 20

check_vpn
if [ \${VPN_status} != 0 ] ; then
	restart_vpn		
fi
"
}

run_slarchive(){
printf "#!/bin/bash

NET_CODE=\`grep network /etc/seedlink/plugins.ini | awk -F\\\\\" '{print \$2}'\`
STA_CODE=\`grep station /etc/seedlink/plugins.ini | awk -F\\\\\" '{print \$2}'\`

/opt/KIGAM/bin/run_with_lock /opt/KIGAM/run/slarchive.pid /opt/KIGAM/bin/slarchive  -b -x /opt/KIGAM/run/slarchive_127.0.0.1_18000.seq:1000000 -SDS /media/data/MSEED -B 10 -nt 900 -nd 30 -i 300 -k 0 -Fi:1 -Fc:900 -S \"\${NET_CODE}_\${STA_CODE}\" 127.0.0.1:18000 &
"
}

config(){
printf "
*********************************************************************
*                                                                   *
*        Configuration File for the 1 & 3 Channel DSS-Cubes         *
*                                                                   *
*                          Software V2.0T                           *
*********************************************************************
* Syntax:                                                           *
*  - Lines beginning with a star '*' are comments (and are ignored) *
*  - Empty lines are not allowed                                    *
*  - Parameter keywords are of six capitalized characters,          *
*    directly followed by an equal sign                             *
*  - The parameter value starts at column #8                        *
*  - Line length is limited to 70 characters                        *
*********************************************************************
****** !!! Parameters for 3 channel Cubes only !!!             ******
*********************************************************************
************************configuration summary************************
* project : ${PROJECT}                                      *
* 작성일자 : ${INITDATE}                                    *
* D-cube serial : ${SERIAL}                                 *
* atctive channels : ch${CH_NUM}                            *
* Amplifier gain : ${P_AMPL}                                *
* sample rate : ${S_RATE} sps                               *
* GPS mode : continuously                                   *
* location : ${LOCATION}                                    *
*********************************************************************
*
** Active Channels      1 = ch1  // 2 = ch1 & ch2  // 3 = ch1 to ch3
CH_NUM=${CH_NUM}
*
** Amplifier Gain       1, 2, 4, 8, 16, 32 or 64 defult 16
P_AMPL=${P_AMPL}
*
** AD Converter Mode    0 = Low power // 1 = High resolution defult 0
C_MODE=0
*
** Amplifier Chopping   0 = off // 1 = on defult 1
A_CHOP=1
*
** AUX_S serial Data Input  0 = off // 1 = on defult 0
AUX_SE=0
*
*********************************************************************
*****   General parameters for 1 and 3 channel Cubes            *****
*********************************************************************
*
** Project Name         Project name of max. 20 characters defult N/A
E_NAME=infrasound
*
** Sample Rate          50, 100, 200, 400, (800@1ch) sps defult 100
S_RATE=${S_RATE}
*
** Digital High Pass    0 = off // 1 = on defult 0
A_FILT=0
*
** FIR Filter           0 = Linear phase // 1 = Minimum phase defult 0
A_PHAS=0
*
** TimeBase Correction  0 = off // 1 = PLL // 2 = DIFF defult 0
PLL_XO=0
*
** Puls Generator start[1-23h]_interval[1-9999h]_length[2-59s]
*MK_PLS=23_24_10
*
** Geographic position lat, lon, alt; to speed up satellite search
*GPS_PO=>SIP+36+127+0000
*
** GPS Mode             0 = cycled // 1 = continuously defult 0
GPS_ON=1
*
** GPS & Flush Interval 3 to 59 minutes
*  (GPS interval only in cycled mode)  
F_TIME=30
*
*********************************************************************
*****   Parameters relevant for GPS cycled mode only            *****
*********************************************************************
** GPS OFF after        0 = 'GPS_TI' // 1 = 60 GPS fixes max.'GPS_TI'
GPS_OF=0
*
** GPS ON Time          3 to 55 minutes
GPS_TI=5
*
"
}

connecting_dcube

cd /mnt/
echo "Modification config.txt"
cp config.txt config_`date +%y%m%d`.txt
config > CONFIG.TXT
echo "####################################################################"
echo "                         Check the config.txt file                  "
echo "####################################################################"
cat config.txt
echo "####################################################################"
echo "####################################################################"
echo ""
read -p "Press enter key to continue."
echo ""
disconnecting_dcube

echo ""
echo "####################################################################"
echo "####################################################################"
echo "The Dcube will reboot."
echo "Please wait until the reboot is complete."
read -p "Is the GPS and ACQ LED blinking normally?  Only uppercase [Y/N] "  answer
if [ ${answer} != "Y" ] ; then
	echo "Error " 
	echo "Unable to proceed."
	exit
fi

echo "sleep 60 (Waiting to Data)"
sleep 60 

echo "Checking the Dcube file"
connecting_dcube
cd /mnt/`date +%y%m%d` 
D_FILT=`ls -art | tail -1 | xargs head -1  |  awk -F\; '{print $7}'`
if [ ${D_FILT} ] ; then
	D_FILT_VALUE=`echo ${D_FILT} | awk -F= '{print $2}'`
	echo ${D_FILT}
	disconnecting_dcube
else 
	echo "###########################"
	echo "Error D_FILT data not found"
	echo "###########################"
	disconnecting_dcube
	exit
fi
sleep 10

echo "Configuration C-Cube"
${CPATH}/ccube-datalogger dcube logger --channels ${CH_NUM} --samples ${S_RATE}  --delay ${D_FILT_VALUE}
${CPATH}/ccube-datalogger dcube plugin --network ${NET} --location ${LOC} --stream ${STREAM} --channels ${CHANNEL} ${STATION}

export LANG=C
echo "make slarchive"
make_slarchive


echo "start seedlink"
systemctl enable seedlink-server
systemctl restart seedlink-server
sleep 10
echo "start ntp"
systemctl enable ntp
systemctl restart ntp
echo "Checking seedlink data"
${CPATH}/slinktool -Q :

echo "Make sysop user : PW = sysop0"
useradd -d /home/sysop -m -s /bin/bash -G sudo sysop
echo "sysop:sysop0" | chpasswd
