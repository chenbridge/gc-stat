#!/bin/bash

################################################################################
# Java GC statistics shell scripts.
# Bridge Chen
# Shenzhen, China
# 2020-10-24
################################################################################

# YGC耗时警告阈值(毫秒)
readonly YGC_TIME_WARN_THRESHOLD=50

# YGC耗时错误阈值(毫秒)
readonly YGC_TIME_ERROR_THRESHOLD=100

# YGC间隔警告阈值(秒)
readonly YGC_INTERVAL_WARN_THRESHOLD=60

# YGC间隔错误阈值(秒)
readonly YGC_INTERVAL_ERROR_THRESHOLD=10

# FGC耗时警告阈值(毫秒)
readonly FGC_TIME_WARN_THRESHOLD=500

# FGC耗时阈值(毫秒)
readonly FGC_TIME_ERROR_THRESHOLD=1000

# FGC间隔警告阈值(秒)
readonly FGC_INTERVAL_WARN_THRESHOLD=3600

# FGC间隔错误阈值(秒)
readonly FGC_INTERVAL_ERROR_THRESHOLD=600

etime=$(ps -o etime $1 | sed -n '2p')
gcutil=$(jstat -gcutil -t $1 | sed -n '2p')

timestamp=$(echo $gcutil | cut -d' ' -f 1)
ygc=$(echo $gcutil | awk '{print $8}')
ygct=$(echo $gcutil | awk '{print $9}')
fgc=$(echo $gcutil | awk '{print $10}')
fgct=$(echo $gcutil | awk '{print $11}')

if [ $ygc -gt 0 ]; then
    ygc_time=$(echo "$ygct * 1000 / $ygc" | bc)
    ygc_interval=$(echo "$timestamp / $ygc" | bc)
else
    ygc_time=0
    ygc_interval=0
fi

if [ $fgc -gt 0 ]; then
    fgc_time=$(echo "$fgct * 1000 / $fgc" | bc)
    fgc_interval=$(echo "$timestamp / $fgc" | bc)
else
    fgc_time=0
    fgc_interval=0
fi

# 显示包名或者主类名
jcmd | grep $1

# 进程运行时间
echo "Process($1)'s elapsed time is $etime"

# YGC时间, 越小越好
if [ $ygc_time -lt $YGC_TIME_WARN_THRESHOLD ]; then
    # YGC时间小于警告阈值, 正常显示
    echo "Process($1)'s YGC average time is $ygc_time ms"
elif [ $ygc_time -ge $YGC_TIME_WARN_THRESHOLD ] && [ $ygc_time -lt $YGC_TIME_ERROR_THRESHOLD ]; then
    # YGC时间大于等于警告阈值且小于错误阈值, 显示黄色
    echo -e "Process($1)'s YGC average time is \e[1;33m $ygc_time \e[0m ms !"
else
    # YGC时间大于等于错误阈值, 显示红色
    echo -e "Process($1)'s YGC average time is \e[1;31m $ygc_time \e[0m ms !!"
fi

# YGC间隔, 越大越好
if [ $ygc_interval -eq 0 ] || [ $ygc_interval -ge $YGC_INTERVAL_WARN_THRESHOLD ]; then
    # YGC间隔为零或者大于等于警告阈值, 正常显示
    echo "Process($1)'s YGC average interval is $ygc_interval s"
elif [ $ygc_interval -lt $YGC_INTERVAL_WARN_THRESHOLD ] && [ $ygc_interval -ge $YGC_INTERVAL_ERROR_THRESHOLD ]; then
    # YGC间隔小于警告阈值且大于等于错误阈值, 显示黄色
    echo -e "Process($1)'s YGC average interval is \e[1;33m $ygc_interval \e[0m s !"
else
    # YGC间隔小于错误阈值, 显示红色
    echo -e "Process($1)'s YGC average interval is \e[1;31m $ygc_interval \e[0m s !!"
fi

# FGC时间, 越小越好
if [ $fgc_time -lt $FGC_TIME_WARN_THRESHOLD ]; then
    # FGC时间小于警告阈值, 正常显示
    echo "Process($1)'s FGC average time is $fgc_time ms"
elif [ $fgc_time -ge $FGC_TIME_WARN_THRESHOLD ] && [ $fgc_time -lt $FGC_TIME_ERROR_THRESHOLD ]; then
    # FGC时间大于等于警告阈值且小于错误阈值, 显示黄色
    echo -e "Process($1)'s FGC average time is \e[1;33m $fgc_time \e[0m ms !"
else
    # FGC时间大于等于错误阈值, 显示红色
    echo -e "Process($1)'s FGC average time is \e[1;31m $fgc_time \e[0m ms !!"
fi

# FGC间隔, 越大越好
if [ $fgc_interval -eq 0 ] || [ $fgc_interval -ge $FGC_INTERVAL_WARN_THRESHOLD ]; then
    # FGC间隔为零或者大于等于警告阈值, 正常显示
    echo "Process($1)'s FGC average interval is $fgc_interval s"
elif [ $fgc_interval -lt $FGC_INTERVAL_WARN_THRESHOLD ] && [ $fgc_interval -ge $FGC_INTERVAL_ERROR_THRESHOLD ]; then
    # FGC间隔小于警告阈值大于等于错误阈值, 显示黄色
    echo -e "Process($1)'s FGC average interval is \e[1;33m $fgc_interval \e[0m s !"
else
    # FGC间隔小于错误阈值, 显示红色
    echo -e "Process($1)'s FGC average interval is \e[1;31m $fgc_interval \e[0m s !!"
fi
