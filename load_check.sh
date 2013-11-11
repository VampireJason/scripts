#!/bin/bash
## create by jason

# define color

RED="\033[0;31m"
GREEN="\033[0;32m"
NO_COLOR="\033[0m"

# check cpu and io

LOAD_IN_1MIN=$(uptime | awk -F ": " '{print $2}' | awk -F "," '{print $1}')
CURRENT_CPU_IDLE=$(vmstat 5 2 | tail -n 1 | awk '{print $(NF-2)}')
CURRENT_CPU_IOWAIT=$(vmstat 5 2 | tail -n 1 | awk '{print $(NF-1)}')
CURRENT_RUN_PROCESS=$(vmstat 5 2 | tail -n 1 | awk '{print $1}')
CURRENT_BLOCK_PROCESS=$(vmstat 5 2 | tail -n 1 | awk '{print $2}')
LOAD_IN_1MIN_PER_CORE=$(echo "scale=2 ; a=$LOAD_IN_1MIN/2 ; if (length(a)==scale(a)) print 0;print a"|bc -l)

cpu_load_check(){

CPU_LOAD=$(expr 100 - $CURRENT_CPU_IDLE - $CURRENT_CPU_IOWAIT)
CPU_CORE=$(cat /proc/cpuinfo | grep processor | tail -n 1 | awk '{print $NF}')

if expr "$CPU_LOAD" \> "50" > /dev/null
then echo -e "$RED cpu load is more than 50% - cpu high. $NO_COLOR"
else echo -e "$GREEN cpu load is less than %50 - cpu low. $NO_COLOR"
fi

if expr "$CURRENT_RUN_PROCESS" \> "$LOAD_IN_1MIN_PER_CORE" > /dev/null
then echo -e "$RED running process is too much than core - cpu high. $NO_COLOR"
else echo -e "$GREEN running process is not much than core - cpu low. $NO_COLOR"
fi

if expr "$LOAD_IN_1MIN" \> "$CPU_CORE" > /dev/null
then echo -e "$RED load avg is more than core - cpu high. $NO_COLOR"
else echo -e "$GREEN load avg is less than core - cpu low. $NO_COLOR"
fi
}

io_check(){

if expr "$CURRENT_CPU_IOWAIT" \> "25" > /dev/null
then echo -e "$RED IO wait is more than 25% - io high. $NO_COLOR"
else echo -e "$GREEN IO wait is less than 25% - io low. $NO_COLOR"
fi

if expr "$CURRENT_BLOCK_PROCESS" \> "$LOAD_IN_1MIN_PER_CORE" > /dev/null
then echo -e "$RED Block processes more than load avg per core - io high. $NO_COLOR"
else echo -e "$GREEN Block processes less than load avg per core - io low. $NO_COLOR"
fi

}

cpu_load_check
io_check
