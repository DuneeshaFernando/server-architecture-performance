#!/usr/bin/env bash

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

backend_program_jars=(blocking blocking.disruptor blocking.actor nio nio.disruptor nio.netty nio.actor nio.actor.seda nio.disruptor.seda nio.queue.seda nio2 nio2.actor nio2.disruptor)
#backend_program_jars=(nio.disruptor.seda)

backend_host_ip=192.168.32.12
backend_host_user=wso2
backend_host_password=javawso2 #wso2123

backend_sar_path=/home/wso2/pasindu/sar_dir
backend_perf_path=/home/wso2/pasindu/perf_dir
backend_gc_path=/home/wso2/pasindu/gc_dir
backend_jar_files_root=/home/wso2/pasindu/server-architectures

backend_script=/home/wso2/pasindu/server-start.sh


jmeter_jtl_location=/home/wso2/pasindu/jtls
jmeter_sar_path=/home/wso2/pasindu/sar_dir
jmeter_perf_path=/home/wso2/pasindu/perf_dir
jmeter_gc_path=/home/wso2/pasindu/gc_dir
jmeter_gc_logs_report_path=/home/wso2/pasindu/gc_reports

jmeter_jmx_file_root=/home/wso2/pasindu/jmx

jmeter_jtl_splitter_jar_file=/home/wso2/pasindu/jtl-splitter-0.3.1-SNAPSHOT.jar

jmeter_jmeter_path=/home/wso2/pasindu/apache-jmeter-4.0/bin

jmeter_performance_report_python_file=/home/wso2/pasindu/python/performance_report.py

jmeter_payload_generator_python_file=/home/wso2/pasindu/python/payload_generator.py

jmeter_performance_report_output_file=/home/wso2/pasindu/results.csv

jmeter_payloads_output_file_root=/home/wso2/pasindu/payloads

jmeter_payload_files_prefix=payload

jmeter_gc_viewer_jar_file=/home/wso2/pasindu/gcviewer-1.36-SNAPSHOT.jar

run_time_length_seconds=120
warm_up_time_seconds=60 # check for min vs sec
warm_up_time_minutes=1

actual_run_time_seconds=60


rm -r ${jmeter_jtl_location}/
rm -r ${jmeter_sar_path}/
rm -r ${jmeter_perf_path}/
rm -r ${jmeter_gc_path}/
rm -r ${jmeter_payloads_output_file_root}/
rm -r ${jmeter_gc_logs_report_path}/
rm  ${jmeter_performance_report_output_file}

mkdir -p ${jmeter_jtl_location}/
mkdir -p ${jmeter_sar_path}/
mkdir -p ${jmeter_perf_path}/
mkdir -p ${jmeter_gc_path}/
mkdir -p ${jmeter_payloads_output_file_root}/
mkdir -p ${jmeter_gc_logs_report_path}/

echo "IO Performance Tests"

echo "Generating Payloads for io use case"

python3 ${jmeter_payload_generator_python_file} ${jmeter_payloads_output_file_root}/${jmeter_payload_files_prefix}

echo "Finished generating payloads"

concurrent_users=(200)
heap_sizes=(1g)
message_sizes=(1024)
garbage_collectors=(UseParallelGC)
use_case=io

for backend_program_jar in ${backend_program_jars[@]}
do
    for size in ${message_sizes[@]}
    do
        for heap in ${heap_sizes[@]}
        do
            for u in ${concurrent_users[@]}
            do
                for gc in ${garbage_collectors[@]}
                do
                    total_users=$(($u))

                    jtl_report_location=${jmeter_jtl_location}/${backend_program_jar}/${use_case}/${heap}_Heap_${total_users}_Users_${gc}_collector_${size}_size

                    echo "Report location is ${jtl_report_location}"

                    mkdir -p $jtl_report_location
                    #
                    nohup sshpass -p 'javawso2' ssh -n -f ${backend_host_user}@${backend_host_ip} "/bin/bash $backend_script ${heap} ${u} ${backend_gc_path} ${backend_sar_path} ${backend_perf_path} ${gc} ${size} ${backend_jar_files_root}/${backend_program_jar}/target/${backend_program_jar}-1.0-SNAPSHOT.jar ${run_time_length_seconds} ${warm_up_time_seconds} ${backend_program_jar}-1.0-SNAPSHOT.jar ${use_case}  ${actual_run_time_seconds}" &

                    sleep 10

                    message=$(<${jmeter_payloads_output_file_root}/${jmeter_payload_files_prefix}${size})

                    # Start JMeter server - no keep alives

                    echo "Starting Jmeter"

                    ${jmeter_jmeter_path}/jmeter  -Jgroup1.host=${backend_host_ip}  -Jgroup1.port=4333 -Jgroup1.threads=$u -Jgroup1.seconds=${run_time_length_seconds} -Jgroup1.data=${message} -Jgroup1.endpoint=${use_case} -Jgroup1.param=message -n -t ${jmeter_jmx_file_root}/jmeter.jmx -l ${jtl_report_location}/results.jtl

                    jtl_file=${jtl_report_location}/results.jtl

                    echo "Splitting JTL"

                    java -jar ${jmeter_jtl_splitter_jar_file} -f $jtl_file -t ${warm_up_time_minutes}

                    jtl_file_measurement_for_this=${jtl_report_location}/results-measurement.jtl

                    echo "Downloading GC Report"
                    sshpass -p 'javawso2' scp -r ${backend_host_user}@${backend_host_ip}:${backend_gc_path}/${backend_program_jar}-1.0-SNAPSHOT.jar/${use_case}/${heap}_Heap_${u}_Users_${gc}_collector_${size}_size_GCLog.txt ${jmeter_gc_path}/${backend_program_jar}-1.0-SNAPSHOT.jar_${use_case}_${heap}_Heap_${u}_Users_${gc}_collector_${size}_size_GCLog.txt

                    gc_log_for_this=${jmeter_gc_path}/${backend_program_jar}-1.0-SNAPSHOT.jar_${use_case}_${heap}_Heap_${u}_Users_${gc}_collector_${size}_size_GCLog.txt

                    echo "Generating GC Reports"

                    gc_report_file_for_this=${jmeter_gc_logs_report_path}/${backend_program_jar}-1.0-SNAPSHOT.jar_${use_case}_${heap}_Heap_${u}_Users_${gc}_collector_${size}_size_GCReport.csv

                    java -jar $jmeter_gc_viewer_jar_file $gc_log_for_this $gc_report_file_for_this
#
                    echo "Downloading CPU SAR"

                    sshpass -p 'javawso2' scp -r ${backend_host_user}@${backend_host_ip}:${backend_sar_path}/${backend_program_jar}-1.0-SNAPSHOT.jar/${use_case}/${heap}_Heap_${u}_Users_${gc}_collector_${size}_size_cpu_sar.txt ${jmeter_sar_path}/${backend_program_jar}-1.0-SNAPSHOT.jar_${use_case}_${heap}_Heap_${u}_Users_${gc}_collector_${size}_size_cpu_sar.txt

                    cpu_sar_file_for_this=${jmeter_sar_path}/${backend_program_jar}-1.0-SNAPSHOT.jar_${use_case}_${heap}_Heap_${u}_Users_${gc}_collector_${size}_size_cpu_sar.txt

                    echo "Downloading Memory SAR"

                    sshpass -p 'javawso2' scp -r ${backend_host_user}@${backend_host_ip}:${backend_sar_path}/${backend_program_jar}-1.0-SNAPSHOT.jar/${use_case}/${heap}_Heap_${u}_Users_${gc}_collector_${size}_size_memory_sar.txt ${jmeter_sar_path}/${backend_program_jar}-1.0-SNAPSHOT.jar_${use_case}_${heap}_Heap_${u}_Users_${gc}_collector_${size}_size_memory_sar.txt

                    memory_sar_file_for_this=${jmeter_sar_path}/${backend_program_jar}-1.0-SNAPSHOT.jar_${use_case}_${heap}_Heap_${u}_Users_${gc}_collector_${size}_size_memory_sar.txt

                    echo "Downloading Swap SAR"

                    sshpass -p 'javawso2' scp -r ${backend_host_user}@${backend_host_ip}:${backend_sar_path}/${backend_program_jar}-1.0-SNAPSHOT.jar/${use_case}/${heap}_Heap_${u}_Users_${gc}_collector_${size}_size_swap_sar.txt ${jmeter_sar_path}/${backend_program_jar}-1.0-SNAPSHOT.jar_${use_case}_${heap}_Heap_${u}_Users_${gc}_collector_${size}_size_swap_sar.txt

                    swap_sar_file_for_this=${jmeter_sar_path}/${backend_program_jar}-1.0-SNAPSHOT.jar_${use_case}_${heap}_Heap_${u}_Users_${gc}_collector_${size}_size_swap_sar.txt

                    echo "Downloading IO SAR"

                    sshpass -p 'javawso2' scp -r ${backend_host_user}@${backend_host_ip}:${backend_sar_path}/${backend_program_jar}-1.0-SNAPSHOT.jar/${use_case}/${heap}_Heap_${u}_Users_${gc}_collector_${size}_size_io_sar.txt ${jmeter_sar_path}/${backend_program_jar}-1.0-SNAPSHOT.jar_${use_case}_${heap}_Heap_${u}_Users_${gc}_collector_${size}_size_io_sar.txt

                    io_sar_file_for_this=${jmeter_sar_path}/${backend_program_jar}-1.0-SNAPSHOT.jar_${use_case}_${heap}_Heap_${u}_Users_${gc}_collector_${size}_size_io_sar.txt

                    echo "Downloading INode SAR"

                    sshpass -p 'javawso2' scp -r ${backend_host_user}@${backend_host_ip}:${backend_sar_path}/${backend_program_jar}-1.0-SNAPSHOT.jar/${use_case}/${heap}_Heap_${u}_Users_${gc}_collector_${size}_size_inode_sar.txt ${jmeter_sar_path}/${backend_program_jar}-1.0-SNAPSHOT.jar_${use_case}_${heap}_Heap_${u}_Users_${gc}_collector_${size}_size_inode_sar.txt

                    inode_sar_file_for_this=${jmeter_sar_path}/${backend_program_jar}-1.0-SNAPSHOT.jar_${use_case}_${heap}_Heap_${u}_Users_${gc}_collector_${size}_size_inode_sar.txt

                    echo "Downloading Context Switch SAR"

                    sshpass -p 'javawso2' scp -r ${backend_host_user}@${backend_host_ip}:${backend_sar_path}/${backend_program_jar}-1.0-SNAPSHOT.jar/${use_case}/${heap}_Heap_${u}_Users_${gc}_collector_${size}_size_context_switch_sar.txt ${jmeter_sar_path}/${backend_program_jar}-1.0-SNAPSHOT.jar_${use_case}_${heap}_Heap_${u}_Users_${gc}_collector_${size}_size_context_switch_sar.txt

                    context_switch_sar_file_for_this=${jmeter_sar_path}/${backend_program_jar}-1.0-SNAPSHOT.jar_${use_case}_${heap}_Heap_${u}_Users_${gc}_collector_${size}_size_context_switch_sar.txt

                    echo "Downloading Run Queue SAR"

                    sshpass -p 'javawso2' scp -r ${backend_host_user}@${backend_host_ip}:${backend_sar_path}/${backend_program_jar}-1.0-SNAPSHOT.jar/${use_case}/${heap}_Heap_${u}_Users_${gc}_collector_${size}_size_run_queue_sar.txt ${jmeter_sar_path}/${backend_program_jar}-1.0-SNAPSHOT.jar_${use_case}_${heap}_Heap_${u}_Users_${gc}_collector_${size}_size_run_queue_sar.txt

                    run_queue_sar_file_for_this=${jmeter_sar_path}/${backend_program_jar}-1.0-SNAPSHOT.jar_${use_case}_${heap}_Heap_${u}_Users_${gc}_collector_${size}_size_run_queue_sar.txt

                    echo "Downloading Network SAR"

                    sshpass -p 'javawso2' scp -r ${backend_host_user}@${backend_host_ip}:${backend_sar_path}/${backend_program_jar}-1.0-SNAPSHOT.jar/${use_case}/${heap}_Heap_${u}_Users_${gc}_collector_${size}_size_network_sar.txt ${jmeter_sar_path}/${backend_program_jar}-1.0-SNAPSHOT.jar_${use_case}_${heap}_Heap_${u}_Users_${gc}_collector_${size}_size_network_sar.txt

                    network_sar_file_for_this=${jmeter_sar_path}/${backend_program_jar}-1.0-SNAPSHOT.jar_${use_case}_${heap}_Heap_${u}_Users_${gc}_collector_${size}_size_network_sar.txt

                    echo "Downloading Perf"

                    sshpass -p 'javawso2' scp -r ${backend_host_user}@${backend_host_ip}:${backend_perf_path}/${backend_program_jar}-1.0-SNAPSHOT.jar/${use_case}/${heap}_Heap_${u}_Users_${gc}_collector_${size}_size_perf.txt ${jmeter_perf_path}/${backend_program_jar}-1.0-SNAPSHOT.jar_${use_case}_${heap}_Heap_${u}_Users_${gc}_collector_${size}_size_perf.txt

                    perf_file_for_this=${jmeter_perf_path}/${backend_program_jar}-1.0-SNAPSHOT.jar_${use_case}_${heap}_Heap_${u}_Users_${gc}_collector_${size}_size_perf.txt

                    echo "Adding data to CSV file"

                    python3 ${jmeter_performance_report_python_file} ${jmeter_performance_report_output_file} ${jtl_file_measurement_for_this} ${gc_report_file_for_this} ${cpu_sar_file_for_this} ${memory_sar_file_for_this} ${swap_sar_file_for_this} ${io_sar_file_for_this} ${inode_sar_file_for_this} ${context_switch_sar_file_for_this} ${run_queue_sar_file_for_this} ${network_sar_file_for_this} ${perf_file_for_this} ${actual_run_time_seconds}  ${backend_program_jar} ${use_case} ${heap} ${u} ${gc} ${size}

                done
            done
        done
    done
done