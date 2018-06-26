#!/bin/bash

set -x

# read arguments
# mountpoint parameters
ADMINPASSWORD=${1}
PASSMOUNT=${2}
DISKURL=${3}
USERNAME=${4}

# azure number of machines
NUMBER_INSTANCES=${5}
VM_SIZE=${6}
NUMBER_PROCESSORS=${7}

# managment
TO_DEL=${8}
SUBSCRIPTION=${9}

# manipulate file share name
# ** remove special characters, and letters to lower case
FILESHARE="${NUMBER_INSTANCES}x${VM_SIZE}"
FILESHARE=$(sed 's/[^a-zA-Z0-9]//g' <<<$FILESHARE )
FILESHARE=$(sed 's/./\L&/g' <<<$FILESHARE )
# FILESHARE is something like : brams4xstandarda3v2

VM_SIZE_FORMATTED=$(sed 's/[^a-zA-Z0-9]//g' <<<$VM_SIZE )
VM_SIZE_FORMATTED=$(sed 's/./\L&/g' <<<$VM_SIZE_FORMATTED )
# VM_SIZE_FORMATTED is something like: standarda3v2

# azure resource group name
GROUP_NAME=legion${RANDOM}
NUMBER_REPETITIONS=3

NUMBER_JOBS=`echo "${NUMBER_INSTANCES} * ${NUMBER_PROCESSORS}" | bc`

mkdir -p results
RESULTS_DIRECTORY="results/${VM_SIZE}_instances_${NUMBER_INSTANCES}_result"
LOG_DIR="results/${VM_SIZE}_${NUMBER_INSTANCES}_${NUMBER_REPETITIONS}_${GROUP_NAME}"
LOG_FILE="${LOG_DIR}/logfile_${VM_SIZE}_${NUMBER_INSTANCES}_${GROUP_NAME}.log"

MINWAIT=120
MAXWAIT=300
MAXWAIT=`echo "$MAXWAIT-$MINWAIT" | bc`


createMachines(){
    echo "Creating the machine number $1"
    az group deployment create --name "${1}unit${RANDOM}" \
                                --resource-group ${GROUP_NAME} \
                                --template-file azuredeploy_w_imageBrams.json \
                                --parameters vmSize="${VM_SIZE}" vmName="${1}rebel${VM_SIZE_FORMATTED}" dnsLabelPrefix="my${GROUP_NAME}dnsprefix${1}" \
    adminPassword=$2 scriptParameterPassMount=$3 scriptParameterDiskUrl=$4 scriptParameterUsername=$5 adminPublicKey="`cat ~/.ssh/id_rsa.pub`" >> ${LOG_FILE}
}

mkdir -p ${LOG_DIR}
date > ${LOG_FILE}

wait
sleep 5

# create a resource group
echo "Creating group ${GROUP_NAME}"
az group create --name ${GROUP_NAME} --location "South Central US"
sleep 15

# Failed to create group
if [ ! $? -eq 0 ]; then
	az group delete --name ${GROUP_NAME} --yes --no-wait
	az storage share delete --name ${FILESHARE} --account-name ${USERNAME} --account-key ${PASSMOUNT}
	echo "Faile to create group ${GROUP_NAME} exiting"
	exit
fi

# save group name (because azure gui is terrible in usability to delete group)
touch /home/username/groups
echo $GROUP_NAME >> /home/username/groups
# if wanna remove all groups at once, execute:
# $ ./remove_groups.sh


# create machines and pass the shared file system
for (( i = 0; i < $NUMBER_INSTANCES + 1 ; i++ )); do
    createMachines $i ${ADMINPASSWORD} ${PASSMOUNT} ${DISKURL}${USERNAME} ${USERNAME} &
    sleep 10
done
wait

if [ "$(grep "ssh " ${LOG_FILE} | wc -l)" -lt "$NUMBER_INSTANCES" ]
then
	az group delete --name ${GROUP_NAME} --yes --no-wait
	az storage share delete --name ${FILESHARE} --account-name ${USERNAME} --account-key ${PASSMOUNT}
	echo "Faile to deploy"
	echo "${NUMBER_INSTANCES} ${VM_SIZE}" >> failed_to_deploy
	exit
fi


#wait while to create the last machine
sleep 85

echo "******************************************"  >> ${LOG_FILE}


# Add access credential for all virtual machines
for i in `grep "ssh " ${LOG_FILE} | cut -d '@' -f 2 | rev | cut -c 2- | rev`; do
    echo " Copy id from $i"
    ssh-keygen -R $i
    ssh-keygen -R `dig +short $i`
    ssh-keyscan -H $i >> ~/.ssh/known_hosts
done

#get the coordinator address (the last one)
SSH_ADDR=`grep "ssh " ${LOG_FILE} | tail -n 1 | cut -c 23- | rev | cut -c 2- | rev`
if [[ -z "${SSH_ADDR}" ]]; then
    echo "Faile to create a VM instace, reverting changes"
    az group delete --resource-group ${GROUP_NAME} --yes --no-wait
fi

# Create an id RSA for the coordenator
ssh ${SSH_ADDR} << EOF
    ssh-keygen -f ~/.ssh/id_rsa -t rsa -N ''
EOF

# copy coordinator (master) credential to all slaves
scp ${SSH_ADDR}:.ssh/id_rsa.pub ${LOG_DIR}/id_rsa_coodinator_${GROUP_NAME}.pub
for i in `grep "ssh " ${LOG_FILE} | cut -d '@' -f 2 | rev | cut -c 2- | rev`; do
    echo "Put ssh key on $i"
    ssh-copy-id -f -i ${LOG_DIR}/id_rsa_coodinator_${GROUP_NAME}.pub "username@${i}"
done

rm ${LOG_DIR}/hostfile
for host in `seq 4 $((${NUMBER_INSTANCES}+3))`; do
    echo "10.0.0.${host}" >> ${LOG_DIR}/hostfile
done

# rm ${LOG_DIR}/hostfile

ssh ${SSH_ADDR} << EOF
    set -x
    # Add all nodes to known hosts and copy the private key to all machines
    rm ~/.ssh/known_hosts
    for host in \`seq 4 $((${NUMBER_INSTANCES}+3))\`; do
        ssh-keyscan -H "10.0.0.\${host}" >> ~/.ssh/known_hosts
        scp .ssh/id_rsa .ssh/id_rsa.pub "10.0.0.\${host}":.ssh
    done
    # Copy known host that contains all machines to all machines
    for host in \`seq 4 $((${NUMBER_INSTANCES}+3))\`; do
        scp .ssh/known_hosts "10.0.0.\${host}":.ssh
    done
EOF


echo $SSH_ADDR > ssh_addr

# cp -r /home/username/BRAMS /home/username/${FILESHARE}
# cp -r /home/username/bin /home/username/${FILESHARE}
# cp -r meteo-only /home/username/${FILESHARE}

scp -r /home/username/BRAMS $SSH_ADDR:
scp -r /home/username/bin $SSH_ADDR:
scp -r /home/username/meteo-only/ $SSH_ADDR:

scp scripts/benchmarks/brams_dir.sh ${SSH_ADDR}:
ssh ${SSH_ADDR} ./brams_dir.sh ${NUMBER_INSTANCES}


scp ${LOG_DIR}/hostfile ${SSH_ADDR}:meteo-only

ssh ${SSH_ADDR} << EOF
  set -x
  cd meteo-only
  export TMPDIR=./tmp
  ulimit -s 65536
  # /opt/mpich3/bin/mpirun -n 64 -f hostfile ./brams 2>&1 | tee log_brams_meteo_only.out
EOF

mkdir -p /home/username/brams_results
scp ${SSH_ADDR}:meteo-only/log_brams_meteo_only.out /home/username/brams_results/log_brams_meteo_only_${FILESHARE}.out

mkdir -p ${RESULTS_DIRECTORY}


# pause "Press [Enter] key to delete the group ${GROUP_NAME}"
# echo "To tedeleting the resource ${GROUP_NAME}"


if [ "$TO_DEL" == "yes" ]
then
	echo "To deleting the resource ${GROUP_NAME}"
	az group delete --name ${GROUP_NAME} --yes --no-wait
fi
# usage example

# az vm deallocate --no-wait --ids $(
#     az vm list --query "[].id" -o tsv | grep -i "${GROUP_NAME}"
# )

# az vm list --query "[].id" -o tsv | grep -i "${GROUP_NAME}"
# example usage
# az vm start --no-wait --ids $(
#     az vm list --query "[].id" -o tsv | grep -i "${GROUP_NAME}"
# )

# az vm stop --no-wait --ids $(
#     az vm list --query "[].id" -o tsv | grep -i "${GROUP_NAME}"
# )

# MOUNTPOINT=~/mountpoint/
# if [ -d "$MOUNTPOINT" ]; then
#     cp -r results "$MOUNTPOINT/results_$(whoami)$(date +%s)"
# fi
