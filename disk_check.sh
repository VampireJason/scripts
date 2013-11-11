#!/bin/bash

VG_BIN=$(whereis vgs | awk '{print $2}')
#VG_TOTAL=$($VG_BIN | awk '{print $6}' | grep -v VSize)
#VG_FREE=$($VG_BIN | awk '{print $7}' | grep -v VFree)
FOLDER_DISK_USAGE1=$(df -h | awk '{print $4}' | egrep *% | awk -F "%" '{print $1}')
DATE=$(date)
RESULT_FILE=/tmp/result.txt
DISK_COMMON_TMP=/tmp/disk_common_tmp
DISK_COMMON=/tmp/disk_common
RED="\033[0;31m"
GREEN="\033[0;32m"
NO_COLOR="\033[0m"
DISK_USAGE_TMP=/tmp/disk_usage_tmp

print_start_info(){
echo "=============
ChinaNetCloud Low Disk Space Check
 Version 1.0
Start Time:  $DATE" > $RESULT_FILE
echo "List VG info" >> $RESULT_FILE
$VG_BIN >> $RESULT_FILE
#echo "The total vg size is $VG_TOTAL" >> $RESULT_FILE
#echo "The free vg size is $VG_FREE" >> $RESULT_FILE
echo " " >> $RESULT_FILE
}

check_folder_part1(){
for usage in $FOLDER_DISK_USAGE1
do
	if [ $usage -ge 80 ]
	then
	FOLDER_DISK_COMMON=$(df -h | egrep -w $usage% | egrep -v -w / | awk '{print $NF}' >> $DISK_COMMON_TMP)
	fi
done

if [ ! -e $DISK_COMMON_TMP -o -z $DISK_COMMON_TMP ]
then
echo "=============
ChinaNetCloud Low Disk Space Check
 Version 1.0
Start Time:  $DATE"
echo " "
echo "All the folder under 80%"
echo " "
echo "Start Time:  $DATE"
echo "End ChinaNetCloud Low Disk Space Check"
echo "=====================================" ; exit 0
else
cat $DISK_COMMON_TMP | sort -n | uniq > $DISK_COMMON
fi

while read line1
do
echo "File system to check: $line1" >> $RESULT_FILE
SIZE=$(df -h | grep -w $line1$ | awk '{print $1}')
FREE=$(df -h | grep -w $line1$ | awk '{print $3}')
FREE_USAGE=$(df -h | grep -w $line1 | awk '{print $4}')
echo "Size: $SIZE" >> $RESULT_FILE
echo "Free: $FREE" >> $RESULT_FILE
echo "Free %: $FREE_USAGE" >> $RESULT_FILE
echo " " >> $RESULT_FILE
done < $DISK_COMMON
}

check_folder_part2(){
while read line2
do
echo -e "$RED Top 5 largest file or dir in $line2 $GREEN" >> $RESULT_FILE
find $line2 -size +10M -exec du -s {} \; | sort -nr > $DISK_USAGE_TMP
head -n 5 $DISK_USAGE_TMP >> $RESULT_FILE
echo " " >> $RESULT_FILE
done < $DISK_COMMON
}

print_end_info(){
echo " " >> $RESULT_FILE
echo "Start Time:  $DATE" >> $RESULT_FILE
echo "End ChinaNetCloud Low Disk Space Check" >> $RESULT_FILE
echo "=====================================" >> $RESULT_FILE
}

print_result(){
cat /tmp/result.txt
rm -rf $DISK_COMMON_TMP
rm -rf $DISK_COMMON
}

print_start_info
check_folder_part1
check_folder_part2
print_end_info
print_result
