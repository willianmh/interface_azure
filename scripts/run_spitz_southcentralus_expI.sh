#!/bin/bash

# the first paramiter is the admin password, the second one is the Mout disk password the tird one is the vmSize the forth is the number of instances



set -x

# read arguments
ADMINPASSWORD=${1}
PASSMOUNT=${2}
DISKURL=${3}
USERNAME=${4}
NUMBER_INSTANCES=${5}

VM_SIZE=${6}
NUMBER_PROCESSORS=${7}

TO_DEL=${8}
SUBSCRIPTION=${9}

# choose file to process
# SPITZ_FILE="simple-syntetic-micro_sorted.su"
SPITZ_FILE="tacutu.su"


# manipulate file share name
# ** remove special characters, and letters to lower case
FILESHARE="spitz${NUMBER_INSTANCES}x${VM_SIZE}"
FILESHARE=$(sed 's/[^a-zA-Z0-9]//g' <<<$FILESHARE )
FILESHARE=$(sed 's/./\L&/g' <<<$FILESHARE )

VM_SIZE_FORMATTED=$(sed 's/[^a-zA-Z0-9]//g' <<<$VM_SIZE )
VM_SIZE_FORMATTED=$(sed 's/./\L&/g' <<<$VM_SIZE_FORMATTED )

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


# createMachinesFromImage(){
#   echo "Creating the machine number $1 from image $2"
#   az vm create --resource-group $GROUP_NAME --name trooper${1}${GROUP_NAME} \
#   --image /subscriptions/de480004-2ade-43c6-a6b1-c7b4f584ebd3/resourceGroups/stardust/providers/Microsoft.Compute/images/myImage \
#   --admin-username username --generate-ssh-keys
# }

createMachines(){
    echo "Creating the machine number $1"
    az group deployment create --name "${1}unit${RANDOM}" --resource-group ${GROUP_NAME} \
    --template-file azuredeploy_w_image${SUBSCRIPTION}.json --parameters vmSize="${VM_SIZE}" vmName="${1}rebel${VM_SIZE_FORMATTED}" dnsLabelPrefix="my${GROUP_NAME}dnsprefix${1}" \
    adminPassword=$2 scriptParameterPassMount=$3 scriptParameterDiskUrl=$4 scriptParameterUsername=$5 adminPublicKey="`cat ~/.ssh/id_rsa.pub`" >> ${LOG_FILE}

}

mkdir -p ${LOG_DIR}
date > ${LOG_FILE}

# create a shared file system, exclusive (private) for this actual experiment
az storage share create --name ${FILESHARE} --account-key ${PASSMOUNT} --account-name ${USERNAME} --quota 15
wait
sleep 5

# create a resource group
echo "Creating group ${GROUP_NAME}"
az group create --name ${GROUP_NAME} --location "South Central US"
sleep 15

if [ ! $? -eq 0 ]; then
	az group delete --name ${GROUP_NAME} --yes --no-wait
	az storage share delete --name ${FILESHARE} --account-name ${USERNAME} --account-key ${PASSMOUNT}
	echo "Faile to create group ${GROUP_NAME} exiting"
	exit
fi

touch /home/username/groups
echo $GROUP_NAME >> /home/username/groups

# create machines and pass the new shared file system
for (( i = 0; i < $NUMBER_INSTANCES + 1 ; i++ )); do
    createMachines $i ${ADMINPASSWORD} ${PASSMOUNT} ${DISKURL}$FILESHARE ${USERNAME} &
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

sudo mkdir -p /home/username/${FILESHARE}
sudo mount -t cifs ${DISKURL}${FILESHARE} /home/username/${FILESHARE} -o vers=3.0,username=${USERNAME},password=${PASSMOUNT},dir_mode=0777,file_mode=0777,sec=ntlmssp
MOUNTPOINT="/home/username/${FILESHARE}"

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

#get the coordinator address (the least one)
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
    echo "10.0.0.${host} slots=${NUMBER_RROCESSORS}" >> ${LOG_DIR}/hostfile
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

# copies files to mount point
# scp -r ../cepetro-codes ${SSH_ADDR}:
# scp ../data/${SPITZ_FILE} ${SSH_ADDR}:

cp -r ../cepetro-codes /home/username/${FILESHARE}
cp -r ../data /home/username/${FILESHARE}

sudo rm -rf /home/username/${FILESHARE}/cepetro-codes/run/spitz-crs

# scp scripts/install_libs.sh ${SSH_ADDR}:~/mymountpoint/
# scp scripts/run_bench_test.sh ${SSH_ADDR}:mymountpoint
# scp scripts/git_clone.sh ${LOG_DIR}/hostfile ${SSH_ADDR}:

ssh ${SSH_ADDR} << EOF
		set -x

    sudo apt-get -qq update
    sudo apt-get -qq install -y gcc
    sudo apt-get -qq install -y g++
    wait
EOF

scp scripts/benchmarks/build-spitz.sh ${SSH_ADDR}:
ssh ${SSH_ADDR} ./build-spitz.sh ${NUMBER_INSTANCES}

scp scripts/benchmarks/run-spitz.sh ${SSH_ADDR}:
ssh ${SSH_ADDR} ./run-spitz.sh ${NUMBER_INSTANCES} ${NUMBER_PROCESSORS} ${VM_SIZE}

# FILE_TO_PROCESS="simple-syntetic-micro_sorted"
FILE_TO_PROCESS="tacutu"
# FILE_TO_PROCESS=${FILE%.*}


mkdir -p /home/username/results
mkdir -p /home/username/results/${VM_SIZE}
cp -r /home/username/${FILESHARE}/data/${FILE_TO_PROCESS}/crs/${VM_SIZE}/* /home/username/results/${VM_SIZE}/
# scp -r ${SSH_ADDR}:mymountpoint/data/${FILE_TO_PROCESS}/crs/${VM_SIZE}/* /home/username/results/${VM_SIZE}/

mkdir -p /home/username/collective/results
mkdir -p /home/username/collective/results/${VM_SIZE}
cp -r /home/username/${FILESHARE}/data/${FILE_TO_PROCESS}/crs/${VM_SIZE}/* /home/username/collective/results/${VM_SIZE}/

mkdir -p ${RESULTS_DIRECTORY}
scp "${SSH_ADDR}:/home/username/*.log" ${RESULTS_DIRECTORY}
scp "${SSH_ADDR}:/home/username/*.sa" ${RESULTS_DIRECTORY}


# pause "Press [Enter] key to delete the group ${GROUP_NAME}"
# echo "To tedeleting the resource ${GROUP_NAME}"

sudo umount /home/username/${FILESHARE}
rm -rf /home/username/${FILESHARE}

if [ "$TO_DEL" == "yes" ]
then
	echo "To deleting the resource ${GROUP_NAME}"
	az group delete --name ${GROUP_NAME} --yes --no-wait
	az storage share delete --name ${FILESHARE} --account-name ${USERNAME} --account-key ${PASSMOUNT}
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
