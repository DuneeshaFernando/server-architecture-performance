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
jar_file=$8
run_time_length_seconds=$9
warm_up_time_seconds=${10}
pgrep_pattern=${11} # should be jar file name without path
pid=""

# example /bin/bash bash/server-start.sh 200m 100 /home/pasindu/Desktop/Test/gc  /home/pasindu/Desktop/Test/sar /home/pasindu/Desktop/Test/perf  UseParallelGC 100 /home/pasindu/Desktop/Test/target/nio-1.0-SNAPSHOT.jar  120 2 nio-1.0-SNAPSHOT.jar


mkdir -p ${target_gc_logs_path}
mkdir -p ${target_sar_reports_path}
mkdir -p ${target_perf_reports_path}


killall java

echo "Starting Server"

nohup java -Xloggc:${target_gc_logs_path}/${heap_size}_Heap_${num_users}_Users_${gc}_collector_${size}_size_GCLog.txt  -verbose:gc -XX:+PrintGCDateStamps -XX:+${gc} -Xms${heap_size} -Xmx${heap_size}  -jar $jar_file &

echo "Sleeping for warm up time"
sleep $warm_up_time_seconds

echo "Collecting CPU sar"
nohup sar -u ALL 1 $run_time_length_seconds > ${target_sar_reports_path}/${heap_size}_Heap_${num_users}_Users_${gc}_collector_${size}_size_cpu_sar.txt &

echo "Collecting memory sar"
nohup sar -r ALL 1 $run_time_length_seconds > ${target_sar_reports_path}/${heap_size}_Heap_${num_users}_Users_${gc}_collector_${size}_size_memory_sar.txt &

echo "Collecting swap sar"
nohup sar -S 1 $run_time_length_seconds > ${target_sar_reports_path}/${heap_size}_Heap_${num_users}_Users_${gc}_collector_${size}_size_swap_sar.txt &

echo "Collecting IO sar"
nohup sar -b 1 $run_time_length_seconds > ${target_sar_reports_path}/${heap_size}_Heap_${num_users}_Users_${gc}_collector_${size}_size_io_sar.txt &

echo "Collecting Inode sar"
nohup sar -v 1  $run_time_length_seconds > ${target_sar_reports_path}/${heap_size}_Heap_${num_users}_Users_${gc}_collector_${size}_size_inode_sar.txt &

echo "Collecting Context Switch sar"
nohup sar -w 1 $run_time_length_seconds > ${target_sar_reports_path}/${heap_size}_Heap_${num_users}_Users_${gc}_collector_${size}_size_context_switch_sar.txt &

echo "Collecting Run Queue sar"
nohup sar -q 1 $run_time_length_seconds > ${target_sar_reports_path}/${heap_size}_Heap_${num_users}_Users_${gc}_collector_${size}_size_run_queue_sar.txt &

echo "Collecting Network sar"
nohup sar -n DEV  1 $run_time_length_seconds > ${target_sar_reports_path}/${heap_size}_Heap_${num_users}_Users_${gc}_collector_${size}_size_network_sar.txt &

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
    nohup perf stat -o ${target_perf_reports_path}/${heap_size}_Heap_${num_users}_Users_${gc}_collector_${size}_size_perf.txt -e task-clock,context-switches,cpu-migrations,page-faults,cache-misses,cycles,instructions,branches,branch-misses  -d -d -p ${pid} -- sleep $run_time_length_seconds &
    echo "perf process ID: $!"
else
    echo "Process with pattern \"$pgrep_pattern\" not found!"
fi