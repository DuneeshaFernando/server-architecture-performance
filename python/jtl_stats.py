import os
import numpy as np


def getLatencyList(filename):
    if os.path.isfile(filename):

        latencies = []
        with open(filename) as f:
            content = f.readlines()
            content=content[1:]
            for row in content:
                success = row.strip().split(",")[7]
                latency = row.strip().split(",")[-3]
                if(success == "true"):
                    latencies.append(int(latency))
        return latencies

    else:
        print("File doesn't exists")
        return []


def getAverageLatency(latency_values):
    return sum(latency_values)/len(latency_values)


def get_percentile(latency_values, percentile):
    return np.percentile(latency_values, percentile)