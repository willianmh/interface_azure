#!/bin/bash

ARG=$1

if [ $ARG = "parallel" ]
then
	echo "running parallel"
	PARALLEL="&"
fi

if [ $ARG = "sequencial" ]
then
	echo "running sequencial"
fi
set -x
for i in `seq 1 150`
do
	echo $(($i * $i *2)) >> $ARG $PARALLEL

done
