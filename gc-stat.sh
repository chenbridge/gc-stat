#!/bin/bash

################################################################################
# Java GC statistics shell scripts.
# Bridge Chen
# Shenzhen, China
# 2020-10-24
################################################################################

# 打印GC的吞吐量、耗时和间隔
# 依赖命令: jstat, ps, sed, awk, bc

# 吞吐量警告阈值
readonly THROUGHPUT_WARN_THRESHOLD=99.9

# 吞吐量错误阈值
readonly THROUGHPUT_ERROR_THRESHOLD=99

# YGC耗时警告阈值(毫秒)
readonly YGC_TIME_WARN_THRESHOLD=50

# YGC耗时错误阈值(毫秒)
readonly YGC_TIME_ERROR_THRESHOLD=200

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

# 使用说明
function  usage() {
    echo "Usage: $0 <PID>"
}

# 主函数
function main() {
    if [ $# -lt 1 ]; then
        usage "$@"
        exit 1
    fi

    PID=$1

    # 获取JVM的GC统计信息
    gcutil=$(jstat -gcutil -t ${PID} | sed -n '2p')

    # 提取相关信息
    # Timestamp         S0     S1     E      O      M     CCS    YGC     YGCT    FGC    FGCT     GCT
    timestamp=$(echo $gcutil | cut -d' ' -f 1)
    ygc=$(echo $gcutil | awk '{print $8}')
    ygct=$(echo $gcutil | awk '{print $9}')
    fgc=$(echo $gcutil | awk '{print $10}')
    fgct=$(echo $gcutil | awk '{print $11}')
    gct=$(echo $gcutil | awk '{print $12}')

    # 计算吞吐量
    throughput=$(echo "scale = 3; ($timestamp - $gct) * 100 / $timestamp" | bc)

    # 计算YGC耗时和间隔
    if [ $ygc -gt 0 ]; then
        ygc_time=$(echo "$ygct * 1000 / $ygc" | bc)
        ygc_interval=$(echo "$timestamp / $ygc" | bc)
    else
        ygc_time=0
        ygc_interval=0
    fi

    # 计算FGC耗时和间隔
    if [ $fgc -gt 0 ]; then
        fgc_time=$(echo "$fgct * 1000 / $fgc" | bc)
        fgc_interval=$(echo "$timestamp / $fgc" | bc)
    else
        fgc_time=0
        fgc_interval=0
    fi

    # 打印PID和包名
    jps -l | grep "^${PID} "

    # 打印进程运行时间
    echo "Elapsed: $(ps -o etime ${PID} | sed -n '2p' | xargs)"
    echo "Timestamp: ${timestamp}"

    # 打印吞吐量(越大越好)
    if [ 1 -eq "$(echo "${throughput} >= ${THROUGHPUT_WARN_THRESHOLD}" | bc)" ]; then
        # 吞吐量大于等于警告阈值, 绿色字体
        echo -e "Throughput: \e[1;32m ${throughput}% \e[0m"
    elif [ 1 -eq "$(echo "${throughput} < ${THROUGHPUT_WARN_THRESHOLD}" | bc)" ] && [ 1 -eq "$(echo "${throughput} >= ${THROUGHPUT_ERROR_THRESHOLD}" | bc)" ]; then
        # 吞吐量小于警告阈值且大于等于错误阈值, 黄色字体
        echo -e "Throughput: \e[1;33m ${throughput}% \e[0m !"
    else
        # 吞吐量小于错误阈值, 红色字体
        echo -e "Throughput: \e[1;31m ${throughput}% \e[0m !!"
    fi


    # 打印YGC耗时(越小越好)
    if [ ${ygc_time} -lt $YGC_TIME_WARN_THRESHOLD ]; then
        # YGC耗时小于警告阈值, 绿色字体
        echo -e "YGC Avg Pause Time: \e[1;32m ${ygc_time} \e[0m ms"
    elif [ ${ygc_time} -ge $YGC_TIME_WARN_THRESHOLD ] && [ ${ygc_time} -lt ${YGC_TIME_ERROR_THRESHOLD} ]; then
        # YGC耗时大于等于警告阈值且小于错误阈值, 黄色字体
        echo -e "YGC Avg Pause Time: \e[1;33m ${ygc_time} \e[0m ms !"
    else
        # YGC耗时大于等于错误阈值, 红色字体
        echo -e "YGC Avg Pause Time: \e[1;31m ${ygc_time} \e[0m ms !!"
    fi

    # 打印YGC间隔(越大越好)
    if [ ${ygc_interval} -eq 0 ] || [ ${ygc_interval} -ge ${YGC_INTERVAL_WARN_THRESHOLD} ]; then
        # YGC间隔为零或者大于等于警告阈值, 绿色字体
        echo -e "YGC Avg Interval Time: \e[1;32m ${ygc_interval} \e[0m s"
    elif [ ${ygc_interval} -lt ${YGC_INTERVAL_WARN_THRESHOLD} ] && [ ${ygc_interval} -ge ${YGC_INTERVAL_ERROR_THRESHOLD} ]; then
        # YGC间隔小于警告阈值且大于等于错误阈值, 黄色字体
        echo -e "YGC Avg Interval Time: \e[1;33m ${ygc_interval} \e[0m s !"
    else
        # YGC间隔小于错误阈值, 红色字体
        echo -e "YGC Avg Interval Time: \e[1;31m ${ygc_interval} \e[0m s !!"
    fi

    # 打印FGC耗时(越小越好)
    if [ ${fgc_time} -lt $FGC_TIME_WARN_THRESHOLD ]; then
        # FGC耗时小于警告阈值, 绿色字体
        echo -e "FGC Avg Pause Time: \e[1;32m ${fgc_time} \e[0m ms"
    elif [ ${fgc_time} -ge $FGC_TIME_WARN_THRESHOLD ] && [ ${fgc_time} -lt ${FGC_TIME_ERROR_THRESHOLD} ]; then
        # FGC耗时大于等于警告阈值且小于错误阈值, 黄色字体
        echo -e "FGC Avg Pause Time: \e[1;33m ${fgc_time} \e[0m ms !"
    else
        # FGC耗时大于等于错误阈值, 红色字体
        echo -e "FGC Avg Pause Time: \e[1;31m ${fgc_time} \e[0m ms !!"
    fi

    # 打印FGC间隔(越大越好)
    if [ ${fgc_interval} -eq 0 ] || [ ${fgc_interval} -ge ${FGC_INTERVAL_WARN_THRESHOLD} ]; then
        # FGC间隔为零或者大于等于警告阈值, 绿色字体
        echo -e "FGC Avg Interval Time: \e[1;32m ${fgc_interval} \e[0m s"
    elif [ ${fgc_interval} -lt ${FGC_INTERVAL_WARN_THRESHOLD} ] && [ ${fgc_interval} -ge ${FGC_INTERVAL_ERROR_THRESHOLD} ]; then
        # FGC间隔小于警告阈值大于等于错误阈值, 黄色字体
        echo -e "FGC Avg Interval Time: \e[1;33m ${fgc_interval} \e[0m s !"
    else
        # FGC间隔小于错误阈值, 红色字体
        echo -e "FGC Avg Interval Time: \e[1;31m ${fgc_interval} \e[0m s !!"
    fi

    echo ""

}

# 脚本入口
main "$@"
