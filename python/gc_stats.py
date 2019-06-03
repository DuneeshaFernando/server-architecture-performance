def readGCfile(gc_log_name):
    gc_parameters = {}
    file = open(gc_log_name, "r")
    content = file.readlines()
    for line in content:
        sline = line.replace(",", "")
        entries = sline[:-1].split(";")

        if(entries[0].strip()=="footprint"):
            gc_parameters["footprint"] = entries[1].strip()

        elif(entries[0].strip()=="avgfootprintAfterFullGC"):
            gc_parameters["avgfootprintAfterFullGC"] =  entries[1].strip()

        elif (entries[0].strip() == "avgFreedMemoryByFullGC"):
            gc_parameters["avgFreedMemoryByFullGC"] = entries[1].strip()

        elif (entries[0].strip() == "avgfootprintAfterGC"):
            gc_parameters["avgfootprintAfterGC"] = entries[1].strip()

        elif (entries[0].strip() == "avgFreedMemoryByGC"):
            gc_parameters["avgFreedMemoryByGC"] = entries[1].strip()

        elif (entries[0].strip() == "avgPause"):
            gc_parameters["avgPause"] = entries[1].strip()

        elif (entries[0].strip() == "minPause"):
            gc_parameters["minPause"] = entries[1].strip()

        elif (entries[0].strip() == "maxPause"):
            gc_parameters["maxPause"] = entries[1].strip()

        elif (entries[0].strip() == "avgGCPause"):
            gc_parameters["avgGCPause"] = entries[1].strip()

        elif (entries[0].strip() == "avgFullGCPause"):
            gc_parameters["avgFullGCPause"] = entries[1].strip()

        elif (entries[0].strip() == "accumPause"):
            gc_parameters["accumPause"] = entries[1].strip()

        elif (entries[0].strip() == "fullGCPause"):
            gc_parameters["fullGCPause"] = entries[1].strip()

        elif (entries[0].strip() == "gcPause"):
            gc_parameters["gcPause"] = entries[1].strip()

        elif (entries[0].strip() == "throughput"):
            gc_parameters["throughput"] = entries[1].strip()

        elif (entries[0].strip() == "Number of full GC"):
            gc_parameters["Number of full GC"] = entries[1].strip()

        elif (entries[0].strip() == "Number of Minor GC"):
            gc_parameters["Number of Minor GC"] = entries[1].strip()

        elif (entries[0].strip() == "freedMemoryPerMin"):
            gc_parameters["freedMemoryPerMin"] = entries[1].strip()

        elif (entries[0].strip() == "gcPerformance"):
            gc_parameters["gcPerformance"] = entries[1].strip()

        elif (entries[0].strip() == "fullGCPerformance"):
            gc_parameters["fullGCPerformance"] = entries[1].strip()

    return gc_parameters