#!/bin/bash


#check network conction
ATTEMPTS=0
while [ $(nc -zw1 google.com 443) ] && [ "$ATTEMPTS" -lt 5 ]; do
  echo "we have NO connectivity" &>> ${LOGFILE}
  sleep 15
  ATTEMPTS=$((ATTEMPTS+1))
done
# Install OPM

sudo apt-get -qq update
# sudo apt-add-repository -y ppa:opm/ppa
# sudo apt-get install -y software-properties-common
# sudo apt-get update
# sudo apt-get install -y libopm-simulators1-bin

sudo apt-get -qq install -y gcc
sudo apt-get -qq install -y g++
