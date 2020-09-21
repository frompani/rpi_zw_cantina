#!/usr/bin/env bash
source /home/pi/bin/config.sh

echo "$TIMESTAMP Inizio script di riavvio bus 1-wire" >> $LOGFILE
echo "cambio modo : output"
sudo gpio mode 7 out
sudo gpio write 7 1
echo "aspetto ..."
sleep 5
sudo gpio write 7 0
echo "cambio modo : input"
sudo gpio mode 7 in

echo "$TIMESTAMP Riavviato bus 1-Wire" >> $LOGFILE
