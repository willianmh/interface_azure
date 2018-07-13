#!/bin/bash
readonly PROGDIR=$(readlink -m $(dirname $0))

PARENT_DIR=$(sed 's/\/[^\/]*$//'<<<$PROGDIR)

for i in $(cat $PARENT_DIR/groups)
do
	echo $i
	# az group delete --resource-group $i --yes --no-wait
	az group delete -n $i --yes --no-wait
	# az storage share delete --name ${FILESHARE} --account-name ${USERNAME} --account-key ${PASSMOUNT}
done

rm $PARENT_DIR/groups
