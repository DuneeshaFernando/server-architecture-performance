#!/bin/bash

# Copyright 2019 WSO2 Inc. (http://wso2.org)
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#
# ----------------------------------------------------------------------------
# Run Performance Tests
# ----------------------------------------------------------------------------

heap_size=$1
num_users=$2
target_gc_logs_path=$3
target_sar_reports_path=$4
target_perf_reports_path=$5
gc=$6
size=$7
architecture=$8
run_time_length_seconds=$9
warm_up_time_seconds=${10}
pgrep_pattern=${11} # should be jar file name without path
use_case=${12}
pid=""
actual_run_time_seconds=${13}


mkdir -p ${target_gc_logs_path}/${pgrep_pattern}/${use_case}
mkdir -p ${target_sar_reports_path}/${pgrep_pattern}/${use_case}
mkdir -p ${target_perf_reports_path}/${pgrep_pattern}/${use_case}


killall java
sleep 5
killall java

echo "Starting Server"

nohup java -Xloggc:${target_gc_logs_path}/${pgrep_pattern}/${use_case}/${heap_size}_Heap_${num_users}_Users_${gc}_collector_${size}_size_GCLog.txt  -verbose:gc -XX:+PrintGCDateStamps -XX:+${gc} -Xms${heap_size} -Xmx${heap_size}  -jar $jar_file &

echo "Sleeping for warm up time"
sleep $warm_up_time_seconds

echo "Collecting Perf"

script_dir=$(dirname "$0")
n=0
until [ $n -ge 60 ]; do
    declare -a pids=($(pgrep -f "$pgrep_pattern"))
    if [[ ${#pids[@]} -gt 2 ]]; then
        echo "WARNING: The pattern \"$pgrep_pattern\" to match process is not unique! PIDs found: ${pids[@]}"
    fi
    for pgrep_pid in ${pids[@]}; do
        if [[ $pgrep_pid != $$ ]]; then
            # Ignore this script's process ID
            pid=$pgrep_pid
            break 2
        fi
    done
    echo "Waiting for the process with pattern \"$pgrep_pattern\""
    sleep 1
    n=$(($n + 1))
done

if [[ -n $pid ]]; then
    echo "Collecting perf stats of the process ID ($pid) with pattern: $pgrep_pattern"
    nohup perf stat -o ${target_perf_reports_path}/${pgrep_pattern}/${use_case}/${heap_size}_Heap_${num_users}_Users_${gc}_collector_${size}_size_perf.txt -e task-clock,context-switches,cpu-migrations,page-faults,cache-misses,cycles,instructions,branches,branch-misses  -d -d -p ${pid} -- sleep $actual_run_time_seconds &
    echo "perf process ID: $!"
else
    echo "Process with pattern \"$pgrep_pattern\" not found!"
fi

echo "Collecting CPU sar"
nohup sar -u ALL 1 $actual_run_time_seconds > ${target_sar_reports_path}/${pgrep_pattern}/${use_case}/${heap_size}_Heap_${num_users}_Users_${gc}_collector_${size}_size_cpu_sar.txt &

echo "Collecting memory sar"
nohup sar -r ALL 1 $actual_run_time_seconds > ${target_sar_reports_path}/${pgrep_pattern}/${use_case}/${heap_size}_Heap_${num_users}_Users_${gc}_collector_${size}_size_memory_sar.txt &

echo "Collecting swap sar"
nohup sar -S 1 $actual_run_time_seconds > ${target_sar_reports_path}/${pgrep_pattern}/${use_case}/${heap_size}_Heap_${num_users}_Users_${gc}_collector_${size}_size_swap_sar.txt &

echo "Collecting IO sar"
nohup sar -b 1 $actual_run_time_seconds > ${target_sar_reports_path}/${pgrep_pattern}/${use_case}/${heap_size}_Heap_${num_users}_Users_${gc}_collector_${size}_size_io_sar.txt &

echo "Collecting Inode sar"
nohup sar -v 1  $actual_run_time_seconds > ${target_sar_reports_path}/${pgrep_pattern}/${use_case}/${heap_size}_Heap_${num_users}_Users_${gc}_collector_${size}_size_inode_sar.txt &

echo "Collecting Context Switch sar"
nohup sar -w 1 $actual_run_time_seconds > ${target_sar_reports_path}/${pgrep_pattern}/${use_case}/${heap_size}_Heap_${num_users}_Users_${gc}_collector_${size}_size_context_switch_sar.txt &

echo "Collecting Run Queue sar"
nohup sar -q 1 $actual_run_time_seconds > ${target_sar_reports_path}/${pgrep_pattern}/${use_case}/${heap_size}_Heap_${num_users}_Users_${gc}_collector_${size}_size_run_queue_sar.txt &

echo "Collecting Network sar"
nohup sar -n DEV  1 $actual_run_time_seconds > ${target_sar_reports_path}/${pgrep_pattern}/${use_case}/${heap_size}_Heap_${num_users}_Users_${gc}_collector_${size}_size_network_sar.txt &