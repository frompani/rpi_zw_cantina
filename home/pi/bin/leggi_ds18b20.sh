#!/usr/bin/env bash
###############################################################
#legge i valori di temp e humidity dal domoticz , legge le temp sul bus 1wire e invia tutto al server mysql remoto
###############################################################
#dati server sql remoto:
#nota : creare la chiave per ssh senza password come utente root locale e rf remoto
#ssh-keygen
#ssh-copy-id -p17122 -i ~/.ssh/id_rsa.pub rf@95.226.138.21
###
ip="95.226.138.21"
port="17122"
user="rf"
file="/home/pi/bin/cont.txt"
contatore=$(cat "$file")
num=2   ###numero di letture prima di aggiornare anche il database 

###############################################################
source /home/pi/bin/config.sh
echo "$TIMESTAMP Inizio lettura temperature" >> $LOGFILE
###############################################################
#retrieve data from domoticz 
###############################################################
t_PT=`curl -s "http://192.168.10.181:8888/json.htm?type=devices&rid=94"|grep \"Temp\"\ \:|cut -d ":" -f 2 |cut -c2-6`
t_P1=`curl -s "http://192.168.10.181:8888/json.htm?type=devices&rid=105"|grep \"Temp\"\ \:|cut -d ":" -f 2 |cut -c2-6`
t_P2=`curl -s "http://192.168.10.181:8888/json.htm?type=devices&rid=106"|grep \"Temp\"\ \:|cut -d ":" -f 2 |cut -c2-6`
H_PT=`curl -s "http://192.168.10.181:8888/json.htm?type=devices&rid=95"|grep \"Humidity\"\ \:|cut -d ":" -f 2 |cut -c2-3`
H_P1=`curl -s "http://192.168.10.181:8888/json.htm?type=devices&rid=107"|grep \"Humidity\"\ \:|cut -d ":" -f 2 |cut -c2-3`
H_P2=`curl -s "http://192.168.10.181:8888/json.htm?type=devices&rid=108"|grep \"Humidity\"\ \:|cut -d ":" -f 2 |cut -c2-3`
#################################################################
#lettura dei DS18B20 sul bus 1-wire
#################################################################
t_ext_muro=`cat /sys/bus/w1/devices/28-80000026d080/w1_slave | sed -n 's/^.*\(t=[^ ]*\).*/\1/p' | sed 's/t=//' | awk '{x=$1}END{print(x/1000)}'`
t_ext_aria=`cat /sys/bus/w1/devices/28-80000026fd33/w1_slave | sed -n 's/^.*\(t=[^ ]*\).*/\1/p' | sed 's/t=//' | awk '{x=$1}END{print(x/1000)}'`
t_bollitore=`cat /sys/bus/w1/devices/28-800000270667/w1_slave | sed -n 's/^.*\(t=[^ ]*\).*/\1/p' | sed 's/t=//' | awk '{x=$1}END{print(x/1000)}'`
t_cantina=`cat /sys/bus/w1/devices/28-00000869203d/w1_slave | sed -n 's/^.*\(t=[^ ]*\).*/\1/p' | sed 's/t=//' | awk '{x=$1}END{print(x/1000)}'`
t_pannello=`cat /sys/bus/w1/devices/28-00000868a62b/w1_slave | sed -n 's/^.*\(t=[^ ]*\).*/\1/p' | sed 's/t=//' | awk '{x=$1}END{print(x/1000)}'`
#################################################################
#check se dati ok
#################################################################
#echo $t_cantina 
#echo $t_bollitore
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
################################################################
echo "$TIMESTAMP aggiorno MYSQL server" >> $LOGFILE
#################################################################
#update MYSQL
#################################################################
#lancio script remoto per inserimento dati in mysql
#echo $t_ext_aria $t_pannello $t_ext_muro $t_cantina $t_bollitore $t_PT $t_P1 $t_P2 $H_PT $H_P1 $H_P2

if [ $contatore -ge $num ] ; then
	echo "$TIMESTAMP Aggiorno MYSQL" >> $LOGFILE
	ssh -p$port $user@$ip "sh /dati/bin/add_data.sh $t_ext_aria $t_pannello $t_ext_muro $t_cantina $t_bollitore $t_PT $t_P1 $t_P2 $H_PT $H_P1 $H_P2"
	echo "0" > $file
else  
	contatore=$((contatore + 1))
	echo $contatore > $file
fi

#################################################################
echo "$TIMESTAMP aggiorno DOMOTICZ" >> $LOGFILE
#################################################################
#update DOMOTICZ
#################################################################
curl -s "http://192.168.10.181:8888/json.htm?type=command&param=udevice&idx=15&nvalue=0&svalue=$t_ext_aria"
curl -s "http://192.168.10.181:8888/json.htm?type=command&param=udevice&idx=20&nvalue=0&svalue=$t_ext_muro"
curl -s "http://192.168.10.181:8888/json.htm?type=command&param=udevice&idx=16&nvalue=0&svalue=$t_bollitore"
curl -s "http://192.168.10.181:8888/json.htm?type=command&param=udevice&idx=18&nvalue=0&svalue=$t_cantina"
curl -s "http://192.168.10.181:8888/json.htm?type=command&param=udevice&idx=19&nvalue=0&svalue=$t_pannello"
#################################################################
echo "$TIMESTAMP FINITO!" >> $LOGFILE
#################################################################
