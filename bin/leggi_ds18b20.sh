#!/usr/bin/env bash
source /home/pi/bin/config.sh

echo "$TIMESTAMP Inizio lettura temperature" >> $LOGFILE

t_ext_muro=`cat /sys/bus/w1/devices/28-80000026d080/w1_slave | sed -n 's/^.*\(t=[^ ]*\).*/\1/p' | sed 's/t=//' | awk '{x=$1}END{print(x/1000)}'`
t_ext_aria=`cat /sys/bus/w1/devices/28-80000026fd33/w1_slave | sed -n 's/^.*\(t=[^ ]*\).*/\1/p' | sed 's/t=//' | awk '{x=$1}END{print(x/1000)}'`
t_bollitore=`cat /sys/bus/w1/devices/28-800000270667/w1_slave | sed -n 's/^.*\(t=[^ ]*\).*/\1/p' | sed 's/t=//' | awk '{x=$1}END{print(x/1000)}'`
t_cantina=`cat /sys/bus/w1/devices/28-00000869203d/w1_slave | sed -n 's/^.*\(t=[^ ]*\).*/\1/p' | sed 's/t=//' | awk '{x=$1}END{print(x/1000)}'`
t_pannello=`cat /sys/bus/w1/devices/28-00000868a62b/w1_slave | sed -n 's/^.*\(t=[^ ]*\).*/\1/p' | sed 's/t=//' | awk '{x=$1}END{print(x/1000)}'`
#################################################################
##check se dati ok
#################################################################
echo $t_cantina 
echo $t_bollitore

if [ $( echo "$t_bollitore < 2" | bc ) -eq 1 ] ; then
	   echo "$TIMESTAMP Rilevata t_bollitore < 2  ---->anomala -->abort" >> $LOGFILE
   exit 1
fi
if [ $( echo "$t_cantina > 60" | bc ) -eq 1 ] ; then
           echo "$TIMESTAMP Rilevata t_cantina >60  ---->anomala -->abort" >> $LOGFILE
   exit 1
fi
if [ $( echo "$t_ext_muro > 60" | bc ) -eq 1 ] ; then
           echo "$TIMESTAMP Rilevata t_ext muro >60  ---->anomala -->abort" >> $LOGFILE
   exit 1
fi
if [ $( echo "$t_ext_aria > 60" | bc ) -eq 1 ] ; then
           echo "$TIMESTAMP Rilevata t_ext_aria >60  ---->anomala -->abort" >> $LOGFILE
   exit 1
fi


#################################################################
echo "$TIMESTAMP aggiorno MYSQL server" >> $LOGFILE
#################################################################
##update MYSQL
#################################################################
link="cloud.frompa.it/add_temp.php?t_ext_aria=$t_ext_aria&t_ext_muro=$t_ext_muro&t_int_muro=$t_int_muro&t_bollitore=$t_bollitore&t_pannello=$t_pannello&t_cantina=$t_cantina"

echo $link
wget -qO- $link &> /dev/null 

#################################################################
echo "$TIMESTAMP aggiorno DOMOTICZ" >> $LOGFILE
#################################################################
#################################################################
##update DOMOTICZ
#################################################################
curl -s "http://192.168.10.181:8888/json.htm?type=command&param=udevice&idx=15&nvalue=0&svalue=$t_ext_aria"
curl -s "http://192.168.10.181:8888/json.htm?type=command&param=udevice&idx=20&nvalue=0&svalue=$t_ext_muro"
curl -s "http://192.168.10.181:8888/json.htm?type=command&param=udevice&idx=16&nvalue=0&svalue=$t_bollitore"
curl -s "http://192.168.10.181:8888/json.htm?type=command&param=udevice&idx=18&nvalue=0&svalue=$t_cantina"
curl -s "http://192.168.10.181:8888/json.htm?type=command&param=udevice&idx=19&nvalue=0&svalue=$t_pannello"
