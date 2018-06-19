#!/bin/bash

# start thats a comment stop #
# echo "Config"  > result.txt
# cat time.out | grep "User time" >> result.txt
# cat time.out | grep "System time"  >> result.txt
# cat time.out | grep "Elapsed"  >> result.txt
#
# sed -ie -e 's/[(][^)]*[)]//g' -e 's/  ,/,/g' -e 's/  / /g' -e 's/	//g' -e 's/ : /	/g' result.txt

# echo "16x16" | tr '\n' ',' >> result.txt
# cat time.out | grep "User time" | tr '\n' ','>> result.txt
# cat time.out | grep "System time" | tr '\n' ',' >> result.txt
# cat time.out | grep "Elapsed" >> result.txt
#
# sed -ie -e 's/[(][^)]*[)]//g' -e '2s/[a-zA-Z]//g' -e '2s/[()]//g' -e '2s/ : //g' -e 's/  ,/,/g' -e '2s/[ ]//g' result.txt
# sed -ie -e 's/	//g' result.txt



LOCATION=$1
# RESULTS_DIRECTORY="/home/username/results"
RESULTS_DIRECTORY="../../results1.0"
RESULT_FILE="$RESULTS_DIRECTORY/result.csv"
echo "Machines" | tr '\n' ',' > $RESULT_FILE
echo "Time" | tr '\n' ',' >> $RESULT_FILE
echo "Cost" >> $RESULT_FILE
# # IFS=$'\n'       # make newlines the only separator
# for j in $(cat ../machines/vm_sizes_$LOCATION)
# do
#     echo "$j" | tr '\n' ',' >> $RESULT_FILE
# done


gcc toSeconds.c -o toSeconds


for i in 1
do
	# echo -e "$i instances" | tr '\n' ',' >> $RESULT_FILE
	for j in $(cat ../machines/vm_sizes_$LOCATION)
	do
			FOLDER=$(sed 's/,.*//' <<<$j )
			echo $FOLDER | tr '\n' ',' >> $RESULT_FILE
			if [ -f "$RESULTS_DIRECTORY/$FOLDER/time-$i.out" ]
			then
				# cat $RESULTS_DIRECTORY/$FOLDER/params-$i.in | grep "MACHINES" | sed 's/[^0-9]//g'| tr '\n' ','

				# get time and convert to seconds
				cat $RESULTS_DIRECTORY/$FOLDER/time-$i.out | grep "Elapsed" > tmp
				sed -i -e 's/[(][^)]*[)]//g;' -e 's/[a-zA-Z]//g' -e 's/[ 	]//g' -e 's/.//' tmp
				gcc toSeconds.c -o toSeconds
				./toSeconds < tmp > tmp.out

				cat tmp.out | tr '\n' ',' >> $RESULT_FILE

				PRICE=$(cat ../machines/vm_sizes_$LOCATION | grep -w $FOLDER | awk -F "\"*,\"*" '{print $5}')
				# PRICE=$(cat ../machines/vm_sizes_$LOCATION | grep -w $FOLDER )
				# PRICE=$(sed -i '/^[^,]*,1,*/d' <<<$PRICE )
				if [ ! -z $PRICE ]
				then
					echo $PRICE >> $RESULT_FILE
				else
					echo "ali" >> $RESULT_FILE
				fi
				# echo "Folder: $FOLDER" >> $RESULT_FILE



			else
				# echo "$j" | tr '\n' ',' >> $RESULT_FILE
				# echo "0" | tr '\n' ',' >> $RESULT_FILE
				echo "0,0" >> $RESULT_FILE
			fi
	done
	echo '' >> $RESULT_FILE
done

# remove a ultima virgula de cada linha
sed -i 's/,$//' $RESULT_FILE
(head -n 1 result.csv && tail -n +2 result.csv | sort -k1 -n -t, ) > $RESULTS_DIRECTORY/analysis_multiple_instances.csv

#
# for i in `seq 0 5`; do
# 	echo " $((2**${i})) cores" | tr '\n' ',' >> result.csv
# done
# sed -i 's/.$//' result.csv
# # cat time.out | grep "User time" | tr '\n' ','>> result.csv
# # cat time.out | grep "System time" | tr '\n' ',' >> result.csv
#
# gcc toSeconds.c -o toSeconds
#
# for i in 1 2 4 8 16 32
# do
# 	echo '' >> result.csv
# 	echo -e "$i instances" | tr '\n' ',' >> result.csv
# 	for j in 1 2 4 8 16 32
# 	do
# 		folder=${i}x${j}cores
# 		if [ -d "$folder" ]
# 		then
# 			echo $folder
# 			cat $folder/time.out | grep "Elapsed"  > temp.in
# 			sed -i -e 's/[(][^)]*[)]//g;' -e 's/[a-zA-Z]//g' -e 's/[ 	]//g' -e 's/.//' temp.in
# 			# gcc toSeconds.c -o toSeconds
# 			./toSeconds < temp.in > temp.out
# 			cat temp.out | tr '\n' ',' >> result.csv
# 			rm temp*
# 		fi
# 	done
# 	sed -i 's/,$//' result.csv
# done
#
# cat result.csv > temp
#
# echo -e "\n\nSpeedUp" >> result.csv
# cat temp >> result.csv
# echo -e "\n\nEfficiency" >> result.csv
#
# sed -i -e 's/ instances//' -e 's/ cores//g' temp
#
# cat temp >> result.csv
# rm temp









# echo "Machines" | tr '\n' ',' > result_all.csv
# for i in `seq 0 5`; do
# 	echo " $((2**${i})) cores," | tr '\n' ',' >> result_all.csv
# done
# sed -i 's/.$//' result_all.csv
# # cat time.out | grep "User time" | tr '\n' ','>> result.csv
# # cat time.out | grep "System time" | tr '\n' ',' >> result.csv
#
# gcc toSeconds.c -o toSeconds
#
# for i in 1 2 4 8 16 32
# do
# 	echo '' >> result_all.csv
# 	echo -e "$i instances" | tr '\n' ',' >> result_all.csv
# 	for j in 1 2 4 8 16 32
# 	do
# 		folder=${i}x${j}cores
# 		if [ -d "$folder" ]
# 		then
# 			echo $folder
# 			cat $folder/time.out | grep "Elapsed"  > temp.in
# 			sed -i -e 's/[(][^)]*[)]//g;' -e 's/[a-zA-Z]//g' -e 's/[ 	]//g' -e 's/.//' temp.in
# 			# gcc toSeconds.c -o toSeconds
# 			./toSeconds < temp.in > temp.out
# 			cat temp.out | tr '\n' ',' >> result_all.csv
# 			rm temp*
# 		fi
# 	done
# 	sed -i 's/,$//' result_all.csv
# done
# for folder in *; do
# 	if [ -d "$folder" ]
# 	then
# 		if [ $folder = "/home/"]
# 		cat $folder/time.out | grep "Elapsed"  > temp
# 		sed -i -e 's/[(][^)]*[)]//g;' -e 's/[a-zA-Z]//g' -e 's/[ 	]//g' -e 's/.//' temp
# 		cat temp >> result.csv
# 		rm temp
# 	fi
# done

# cat time.out | grep "Elapsed"  > temp

# sed -ie -e 's/[(][^)]*[)]//g;' -e 's/[a-zA-Z]//g' -e 's/[ 	]//g' -e 's/.//' temp
# cat temp >> result.csv
# rm temp

#
# sed -ie -e 's/[.:]//g' -e 's/[0-9]//g' -e 's/[(][^)]*[)]//g' -e 's/  ,/,/g' -e 's/  / /g' result.csv
#
# # echo "16x16" | tr '\n' ',' >> result.txt
# cat time.out | grep "User time" | tr '\n' ','>> result.csv
# cat time.out | grep "System time" | tr '\n' ',' >> result.csv
# cat time.out | grep "Elapsed" >> result.csv
#
# sed -ie -e 's/[(][^)]*[)]//g' -e '2s/[a-zA-Z]//g' -e '2s/[()]//g' -e '2s/ : //g' -e 's/  ,/,/g' -e '2s/[ ]//g' result.csv
# sed -ie -e 's/	//g' result.csv

# start thats a comment stop #
# echo "Config" | tr '\n' ',' > result.txt
# cat time.out | grep "User time" | tr '\n' ','>> result.txt
# cat time.out | grep "System time" | tr '\n' ',' >> result.txt
# cat time.out | grep "Elapsed"  >> result.txt
#
# sed -ie -e 's/[.:]//g' -e 's/[0-9]//g' -e 's/[(][^)]*[)]//g' -e 's/  ,/,/g' -e 's/  / /g' result.txt
#
# # echo "16x16" | tr '\n' ',' >> result.txt
# cat time.out | grep "User time" | tr '\n' ','>> result.txt
# cat time.out | grep "System time" | tr '\n' ',' >> result.txt
# cat time.out | grep "Elapsed" >> result.txt
#
# sed -ie -e 's/[(][^)]*[)]//g' -e '2s/[a-zA-Z]//g' -e '2s/[()]//g' -e '2s/ : //g' -e 's/  ,/,/g' -e '2s/[ ]//g' result.txt
# sed -ie -e 's/	//g' result.txt
