#!/bin/bash
readonly PROGNAME=$(basename $0)
readonly PROGDIR=$(readlink -m $(dirname $0))

#
# cp ../machines/tableExport.csv ../machines/tableExport-southcentralus.csv
# cp ../machines/tableExport-southcentralus.csv ../machines/vm_sizes_southcentralus
# grep -v ",1," ../machines/tableExport-southcentralus.csv > ../machines/vm_sizes_southcentralus.tmp
# # grep -v ",2," ../machines/vm_sizes_southcentralus.tmp > ../machines/vm_sizes_southcentralus
# # rm ../machines/vm_sizes_southcentralus.tmp
#
# # grep "*,[0-9]*,*" ../machines/vm_sizes_southcentralus
# sed -i '1d' ../machines/vm_sizes_southcentralus
# sed -i 's/["][^"]*["]//g;' ../machines/vm_sizes_southcentralus
# sed -i 's/,$//' ../machines/vm_sizes_southcentralus
#
# sort -k1 -t, ../machines/vm_sizes_southcentralus > ../machines/vm_sizes_southcentralus_sort
# # for i in $(cat tableExport.csv | sed )
#
# # for i in $(cat ../machines/vm_sizes_southcentralus)
# # do
# # 	# echo $i
# # 	echo $(sed 's/[^,]*,\([^,]*\).*/\1/' <<<$i)
# # 	# echo $(sed 's/,.*//' <<<$i )
# #
# # done
#
#
# for i in $(cat jef_vm_sizes | sed -e 's/[^"]*["]//' -e 's/".*//')
#
# for i in `seq 1 64`
# do
# 	TMP=$(egrep ".*,$i,.*,.*,.*,.*" ../machines/vm_sizes_southcentralus_sort)
# 	if [ ! -z "$TMP" ]
# 	then
# 		egrep ".*,$i,.*,.*,.*,.*" ../machines/vm_sizes_southcentralus_sort > ../machines/vm_sizes_southcentralus_$i
# 	fi
# done

az vm list-sizes -l southcentralus --output tsv > sizes
cut -f 3,4 sizes | tr "\\t" "," > vm_sizes_southcentralus


PARENT_DIR=$(sed 's/\/[^\/]*$//'<<<$PROGDIR)


for i in `seq 1 100`
do
	TMP=$(grep -w "$i" vm_sizes_southcentralus)
	if [ ! -z "$TMP" ]
	then
		grep -w "$i" vm_sizes_southcentralus > $PARENT_DIR/machines/vm_sizes_southcentralus_$i
	fi
done
