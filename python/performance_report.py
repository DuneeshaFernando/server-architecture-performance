import sys
import os.path
import csv
from python.jtl_stats import *
from python.gc_stats import *
from python.perf_stats import *
from python.sar_stats import *

def getIfHasAttribute(dictionary, key):
    if(key in list(dictionary.keys())):
        return dictionary[key]
    else:
        return "NA"


output_csv_file = sys.argv[1]

jtl_file_measurement_for_this= sys.argv[2]
gc_report_file_for_this= sys.argv[3]

cpu_sar_file_for_this= sys.argv[4]
memory_sar_file_for_this= sys.argv[5]
swap_sar_file_for_this= sys.argv[6]
io_sar_file_for_this= sys.argv[7]
inode_sar_file_for_this= sys.argv[8]
context_switch_sar_file_for_this= sys.argv[9]
run_queue_sar_file_for_this= sys.argv[10]
network_sar_file_for_this= sys.argv[11]

perf_file_for_this= sys.argv[12]

run_time_seconds= sys.argv[13]

backend_program_jar= sys.argv[14]
use_case= sys.argv[15]
heap= sys.argv[16]
u= sys.argv[17]
gc= sys.argv[18]
size= sys.argv[19]

csv_file_records = []
basic_headers = ['backend architecture', 'use case', 'heap', 'concurrency', 'garbage collector', 'workload']
basic_values = [backend_program_jar, use_case, heap, u, gc, size]

jtl_headers=['average_latency', 'min_latency', 'max_latency', 'percentile_10', 'percentile_20',
             'percentile_50', 'percentile_90', 'percentile_99', 'percentile_999', 'percentile_9999', 'percentile_99999', 'percentile_999999', 'percentile_9999999', 'throughput']
jtl_values=[]

if os.path.isfile(jtl_file_measurement_for_this):
    latency = getLatencyList(jtl_file_measurement_for_this)
    jtl_values.append(getAverageLatency(latency))
    jtl_values.append(min(latency))
    jtl_values.append(max(latency))

    jtl_values.append(get_percentile(latency, 10))
    jtl_values.append(get_percentile(latency, 20))
    jtl_values.append(get_percentile(latency, 50))
    jtl_values.append(get_percentile(latency, 90))
    jtl_values.append(get_percentile(latency, 99))
    jtl_values.append(get_percentile(latency, 999))
    jtl_values.append(get_percentile(latency, 9999))
    jtl_values.append(get_percentile(latency, 99999))
    jtl_values.append(get_percentile(latency, 999999))
    jtl_values.append(get_percentile(latency, 9999999))

    jtl_values.append(len(latency)/run_time_seconds)

gc_headers = ['footprint', 'avgfootprintAfterFullGC', 'avgFreedMemoryByFullGC', 'avgfootprintAfterGC', 'avgFreedMemoryByGC', 'avgPause', 'minPause', 'maxPause',
'avgGCPause', 'avgFullGCPause', 'accumPause', 'fullGCPause', 'gcPause', 'gc_throughput' , 'num_full_gc', 'num_minor_gc', 'freedMemoryPerMin', 'gcPerformance',
'fullGCPerformance' ]

gc_values = []



if (os.path.isfile(gc_report_file_for_this)):

    gc_parameters = readGCfile(gc_report_file_for_this)

    gc_values.append(getIfHasAttribute(gc_parameters, "footprint"))
    gc_values.append(getIfHasAttribute(gc_parameters, "avgfootprintAfterFullGC"))
    gc_values.append(getIfHasAttribute(gc_parameters, "avgFreedMemoryByFullGC"))
    gc_values.append(getIfHasAttribute(gc_parameters, "avgfootprintAfterGC"))
    gc_values.append(getIfHasAttribute(gc_parameters, "avgFreedMemoryByGC"))
    gc_values.append(getIfHasAttribute(gc_parameters, "avgPause"))
    gc_values.append(getIfHasAttribute(gc_parameters, "minPause"))
    gc_values.append(getIfHasAttribute(gc_parameters, "maxPause"))
    gc_values.append(getIfHasAttribute(gc_parameters, "avgGCPause"))
    gc_values.append(getIfHasAttribute(gc_parameters, "avgFullGCPause"))
    gc_values.append(getIfHasAttribute(gc_parameters, "accumPause"))
    gc_values.append(getIfHasAttribute(gc_parameters, "fullGCPause"))
    gc_values.append(getIfHasAttribute(gc_parameters, "gcPause"))
    gc_values.append(getIfHasAttribute(gc_parameters, "throughput"))
    gc_values.append(getIfHasAttribute(gc_parameters, "Number of full GC"))
    gc_values.append(getIfHasAttribute(gc_parameters, "Number of Minor GC"))
    gc_values.append(getIfHasAttribute(gc_parameters, "freedMemoryPerMin"))
    gc_values.append(getIfHasAttribute(gc_parameters, "gcPerformance"))
    gc_values.append(getIfHasAttribute(gc_parameters, "fullGCPerformance"))


perf_stat_values = get_stats(perf_file_for_this)
perf_headers = perf_stat_values[0]
perf_values = perf_stat_values[1]

cpu_sar_stat_values = get_cpu_stats(cpu_sar_file_for_this)
cpu_sar_headers = cpu_sar_stat_values[0]
cpu_sar_values = cpu_sar_stat_values[1]

memory_sar_stat_values = get_memory_stats(memory_sar_file_for_this)
memory_sar_headers = memory_sar_stat_values[0]
memory_sar_values = memory_sar_stat_values[1]

swap_sar_stat_values = get_swap_stats(swap_sar_file_for_this)
swap_sar_headers = swap_sar_stat_values[0]
swap_sar_values = swap_sar_stat_values[1]

io_sar_stat_values = get_io_stats(io_sar_file_for_this)
io_sar_headers = io_sar_stat_values[0]
io_sar_values = io_sar_stat_values[1]

inode_sar_stat_values = get_inode_stats(inode_sar_file_for_this)
inode_sar_headers = inode_sar_stat_values[0]
inode_sar_values = inode_sar_stat_values[1]

context_switch_sar_stat_values = get_context_switch_stats(context_switch_sar_file_for_this)
context_switch_sar_headers = context_switch_sar_stat_values[0]
context_switch_sar_values = context_switch_sar_stat_values[1]

run_queue_sar_stat_values = get_queue_length_stats(run_queue_sar_file_for_this)
run_queue_sar_headers = run_queue_sar_stat_values[0]
run_queue_sar_values = run_queue_sar_stat_values[1]

network_sar_stat_values = get_network_stats(network_sar_file_for_this)
network_sar_headers = network_sar_stat_values[0]
network_sar_values = network_sar_stat_values[1]

if not os.path.isfile(output_csv_file):
    with open(output_csv_file, "a+") as csv_file:
        writer = csv.writer(csv_file, delimiter=',')
        headers = basic_headers+ jtl_headers + gc_headers + perf_headers+ cpu_sar_headers+ memory_sar_headers+ swap_sar_headers+io_sar_headers+inode_sar_headers+context_switch_sar_headers + run_queue_sar_headers+ network_sar_headers
        writer.writerow(headers)

with open(output_csv_file, "a+") as csv_file:
    writer = csv.writer(csv_file, delimiter=',')
    values =  basic_values + jtl_values + gc_values + perf_values + cpu_sar_values + memory_sar_values+ swap_sar_values + io_sar_values + inode_sar_values + context_switch_sar_values + run_queue_sar_values + network_sar_values
    writer.writerow(values)







