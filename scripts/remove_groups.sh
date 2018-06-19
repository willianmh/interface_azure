#!/bin/bash


for i in $(cat ../../groups)
do
	echo $i
	# az group delete --resource-group $i --yes --no-wait
	az group delete -n $i --yes --no-wait
	# az storage share delete --name ${FILESHARE} --account-name ${USERNAME} --account-key ${PASSMOUNT}
done
