#!/bin/bash


NUMBER_INSTANCES=$1

 for host in `seq 4 $((${NUMBER_INSTANCES}+3))`; do
   scp -r /home/username/BRAMS 10.0.0.${host}:
   scp -r /home/username/bin 10.0.0.${host}:
   scp -r /home/username/meteo-only 10.0.0.${host}:
   # ssh 10.0.0.${host} "ln -s /home/username/bin/brams-5.3 /home/username/meteo-only/brams"
done
wait
