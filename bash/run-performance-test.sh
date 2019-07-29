#!/usr/bin/env bash

# Copyright 2019 ubuntu Inc. (http://ubuntu.org)
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

server_architectures=(nio oio seda)

backend_host_ip=192.168.32.12 # to be changed
backend_host_port=9090 # to be changed
backend_host_user=ubuntu
backend_host_key=/home/ubuntu/pasindu/pasindut-ballerina.pem

backend_sar_path=/home/ubuntu/pasindu/sar_dir
backend_perf_path=/home/ubuntu/pasindu/perf_dir
backend_gc_path=/home/ubuntu/pasindu/gc_dir
backend_ballerina_root=/home/ubuntu/pasindu/ballerina

backend_script=/home/ubuntu/pasindu/server-start.sh


jmeter_jtl_location=/home/ubuntu/pasindu/jtls
jmeter_sar_path=/home/ubuntu/pasindu/sar_dir
jmeter_perf_path=/home/ubuntu/pasindu/perf_dir
jmeter_gc_path=/home/ubuntu/pasindu/gc_dir
jmeter_gc_logs_report_path=/home/ubuntu/pasindu/gc_reports

jmeter_jmx_file_root=/home/ubuntu/pasindu/jmx

jmeter_jtl_splitter_jar_file=/home/ubuntu/pasindu/jtl-splitter-0.3.1-SNAPSHOT.jar

jmeter_jmeter_path=/home/ubuntu/pasindu/apache-jmeter-4.0/bin

jmeter_performance_report_python_file=/home/ubuntu/pasindu/python/performance_report.py

jmeter_payload_generator_python_file=/home/ubuntu/pasindu/python/payload_generator.py

jmeter_performance_report_output_file=/home/ubuntu/pasindu/ballerina_results.csv

jmeter_payloads_output_file_root=/home/ubuntu/pasindu/payloads

jmeter_payload_files_prefix=payload

jmeter_gc_viewer_jar_file=/home/ubuntu/pasindu/gcviewer-1.36-SNAPSHOT.jar

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

concurrent_users=(10000 5000 1000 500 100 10)
heap_sizes=(8g)
message_sizes=(102400 1024 10)
garbage_collectors=(UseParallelGC)
use_case=io
param_name=message
request_timeout=50000

for architecture in ${server_architectures[@]}
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

                    jtl_report_location=${jmeter_jtl_location}/${architecture}/${use_case}/${heap}_Heap_${total_users}_Users_${gc}_collector_${size}_size

                    echo "Report location is ${jtl_report_location}"

                    mkdir -p $jtl_report_location

                    nohup ssh  -n -f ${backend_host_user}@${backend_host_ip} -i ${backend_host_key} "/bin/bash $backend_script ${heap} ${u} ${backend_gc_path} ${backend_sar_path} ${backend_perf_path} ${gc} ${size} ${architecture} ${run_time_length_seconds} ${warm_up_time_seconds} java ${use_case}  ${actual_run_time_seconds}" &

                    sleep 10

                    message=$(<${jmeter_payloads_output_file_root}/${jmeter_payload_files_prefix}${size})

                    echo "Starting Jmeter"

                    ${jmeter_jmeter_path}/jmeter  -Jgroup1.host=${backend_host_ip}  -Jgroup1.port=${backend_host_port} -Jgroup1.threads=$u -Jgroup1.seconds=${run_time_length_seconds} -Jgroup1.data=${message} -Jgroup1.endpoint=${use_case} -Jgroup1.param=${param_name} -Jgroup1.timeout=${request_timeout} -n -t ${jmeter_jmx_file_root}/jmeter.jmx -l ${jtl_report_location}/results.jtl

                    jtl_file=${jtl_report_location}/results.jtl

                    echo "Splitting JTL"

                    java -jar ${jmeter_jtl_splitter_jar_file} -f $jtl_file -t ${warm_up_time_minutes}

                    jtl_file_measurement_for_this=${jtl_report_location}/results-measurement.jtl

                    echo "Downloading GC Report"
                    scp -i pasindut.pem -r ${backend_host_user}@${backend_host_ip}:${backend_gc_path}/${architecture}/${use_case}/${heap}_Heap_${u}_Users_${gc}_collector_${size}_size_GCLog.txt ${jmeter_gc_path}/${architecture}_${use_case}_${heap}_Heap_${u}_Users_${gc}_collector_${size}_size_GCLog.txt

                    gc_log_for_this=${jmeter_gc_path}/${architecture}_${use_case}_${heap}_Heap_${u}_Users_${gc}_collector_${size}_size_GCLog.txt

                    echo "Generating GC Reports"

                    gc_report_file_for_this=${jmeter_gc_logs_report_path}/${architecture}_${use_case}_${heap}_Heap_${u}_Users_${gc}_collector_${size}_size_GCReport.csv

                    java -jar $jmeter_gc_viewer_jar_file $gc_log_for_this $gc_report_file_for_this
#
                    echo "Downloading CPU SAR"

                    scp -i pasindut.pem -r ${backend_host_user}@${backend_host_ip}:${backend_sar_path}/${architecture}/${use_case}/${heap}_Heap_${u}_Users_${gc}_collector_${size}_size_cpu_sar.txt ${jmeter_sar_path}/${architecture}_${use_case}_${heap}_Heap_${u}_Users_${gc}_collector_${size}_size_cpu_sar.txt

                    cpu_sar_file_for_this=${jmeter_sar_path}/${architecture}_${use_case}_${heap}_Heap_${u}_Users_${gc}_collector_${size}_size_cpu_sar.txt

                    echo "Downloading Memory SAR"

                    scp -i pasindut.pem  -r ${backend_host_user}@${backend_host_ip}:${backend_sar_path}/${architecture}/${use_case}/${heap}_Heap_${u}_Users_${gc}_collector_${size}_size_memory_sar.txt ${jmeter_sar_path}/${architecture}_${use_case}_${heap}_Heap_${u}_Users_${gc}_collector_${size}_size_memory_sar.txt

                    memory_sar_file_for_this=${jmeter_sar_path}/${architecture}_${use_case}_${heap}_Heap_${u}_Users_${gc}_collector_${size}_size_memory_sar.txt

                    echo "Downloading Swap SAR"

                    scp -i pasindut.pem  -r ${backend_host_user}@${backend_host_ip}:${backend_sar_path}/${architecture}/${use_case}/${heap}_Heap_${u}_Users_${gc}_collector_${size}_size_swap_sar.txt ${jmeter_sar_path}/${architecture}_${use_case}_${heap}_Heap_${u}_Users_${gc}_collector_${size}_size_swap_sar.txt

                    swap_sar_file_for_this=${jmeter_sar_path}/${architecture}_${use_case}_${heap}_Heap_${u}_Users_${gc}_collector_${size}_size_swap_sar.txt

                    echo "Downloading IO SAR"

                    scp -i pasindut.pem  -r ${backend_host_user}@${backend_host_ip}:${backend_sar_path}/${architecture}/${use_case}/${heap}_Heap_${u}_Users_${gc}_collector_${size}_size_io_sar.txt ${jmeter_sar_path}/${architecture}_${use_case}_${heap}_Heap_${u}_Users_${gc}_collector_${size}_size_io_sar.txt

                    io_sar_file_for_this=${jmeter_sar_path}/${architecture}_${use_case}_${heap}_Heap_${u}_Users_${gc}_collector_${size}_size_io_sar.txt

                    echo "Downloading INode SAR"

                    scp -i pasindut.pem  -r ${backend_host_user}@${backend_host_ip}:${backend_sar_path}/${architecture}/${use_case}/${heap}_Heap_${u}_Users_${gc}_collector_${size}_size_inode_sar.txt ${jmeter_sar_path}/${architecture}_${use_case}_${heap}_Heap_${u}_Users_${gc}_collector_${size}_size_inode_sar.txt

                    inode_sar_file_for_this=${jmeter_sar_path}/${architecture}_${use_case}_${heap}_Heap_${u}_Users_${gc}_collector_${size}_size_inode_sar.txt

                    echo "Downloading Context Switch SAR"

                    scp -i pasindut.pem  -r ${backend_host_user}@${backend_host_ip}:${backend_sar_path}/${architecture}/${use_case}/${heap}_Heap_${u}_Users_${gc}_collector_${size}_size_context_switch_sar.txt ${jmeter_sar_path}/${architecture}_${use_case}_${heap}_Heap_${u}_Users_${gc}_collector_${size}_size_context_switch_sar.txt

                    context_switch_sar_file_for_this=${jmeter_sar_path}/${architecture}_${use_case}_${heap}_Heap_${u}_Users_${gc}_collector_${size}_size_context_switch_sar.txt

                    echo "Downloading Run Queue SAR"

                    scp -i pasindut.pem  -r ${backend_host_user}@${backend_host_ip}:${backend_sar_path}/${architecture}/${use_case}/${heap}_Heap_${u}_Users_${gc}_collector_${size}_size_run_queue_sar.txt ${jmeter_sar_path}/${architecture}_${use_case}_${heap}_Heap_${u}_Users_${gc}_collector_${size}_size_run_queue_sar.txt

                    run_queue_sar_file_for_this=${jmeter_sar_path}/${architecture}_${use_case}_${heap}_Heap_${u}_Users_${gc}_collector_${size}_size_run_queue_sar.txt

                    echo "Downloading Network SAR"

                    scp -i pasindut.pem  -r ${backend_host_user}@${backend_host_ip}:${backend_sar_path}/${architecture}/${use_case}/${heap}_Heap_${u}_Users_${gc}_collector_${size}_size_network_sar.txt ${jmeter_sar_path}/${architecture}_${use_case}_${heap}_Heap_${u}_Users_${gc}_collector_${size}_size_network_sar.txt

                    network_sar_file_for_this=${jmeter_sar_path}/${architecture}_${use_case}_${heap}_Heap_${u}_Users_${gc}_collector_${size}_size_network_sar.txt

                    echo "Downloading Perf"

                    scp -i pasindut.pem  -r ${backend_host_user}@${backend_host_ip}:${backend_perf_path}/${architecture}/${use_case}/${heap}_Heap_${u}_Users_${gc}_collector_${size}_size_perf.txt ${jmeter_perf_path}/${architecture}_${use_case}_${heap}_Heap_${u}_Users_${gc}_collector_${size}_size_perf.txt

                    perf_file_for_this=${jmeter_perf_path}/${architecture}_${use_case}_${heap}_Heap_${u}_Users_${gc}_collector_${size}_size_perf.txt

                    echo "Adding data to CSV file"

                    python3 ${jmeter_performance_report_python_file} ${jmeter_performance_report_output_file} ${jtl_file_measurement_for_this} ${gc_report_file_for_this} ${cpu_sar_file_for_this} ${memory_sar_file_for_this} ${swap_sar_file_for_this} ${io_sar_file_for_this} ${inode_sar_file_for_this} ${context_switch_sar_file_for_this} ${run_queue_sar_file_for_this} ${network_sar_file_for_this} ${perf_file_for_this} ${actual_run_time_seconds}  ${architecture} ${use_case} ${heap} ${u} ${gc} ${size}

                done
            done
        done
    done
done

echo "################################## IO Performance tests finished ############################################"

################################################################################################################################################################################
echo "CPU Performance Tests"

concurrent_users=(300 10)
heap_sizes=(2g 100m)
message_sizes=(27059 11)
garbage_collectors=(UseParallelGC)
use_case=cpu
param_name=number
request_timeout=50000


echo "################################## CPU Performance tests finished ############################################"

#################################################################################################################################################################################

echo "Memory Performance Tests"


concurrent_users=(300 10)
heap_sizes=(2g 100m)
message_sizes=(1000 10)
garbage_collectors=(UseParallelGC)
use_case=memory
param_name=number
request_timeout=50000



echo "################################## Memory Performance tests finished ############################################"

################################################################################################################################################################

echo "DB Performance Tests"


concurrent_users=(300 10)
heap_sizes=(2g 100m)
message_sizes=(NA)
garbage_collectors=(UseParallelGC)
use_case=db
param_name=id
request_timeout=50000



echo "################################## DB Performance tests finished ############################################"

###############################################################################################################################################################################

echo "################################## All Performance tests finished ############################################"