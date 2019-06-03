import os

def get_cpu_stats(filename):
    result = [['%usr',     '%nice',      '%sys',   '%iowait',    '%steal',      '%irq',     '%soft',    '%guest',    '%gnice',   '%idle']]
    if os.path.isfile(filename):
        with open(filename) as f:
            content = f.readlines()
            for line in content:
                if(line.startswith("Average")):
                    line = line.strip().split(" ")
                    new_line= []
                    for i in line:
                        if len(i.strip())!=0:
                            new_line.append(i)
                    result.append(new_line[2:])
                    return result

# result = get_cpu_stats("/home/pasindu/Desktop/filename.txt")

def get_memory_stats(filename):
    result = [['kbmemfree',   'kbavail', 'kbmemused',  '%memused', 'kbbuffers',  'kbcached',  'kbcommit',   '%commit',  'kbactive',   'kbinact',   'kbdirty',  'kbanonpg',    'kbslab',  'kbkstack',   'kbpgtbl',  'kbvmused']]
    if os.path.isfile(filename):
        with open(filename) as f:
            content = f.readlines()
            for line in content:
                if(line.startswith("Average")):
                    line = line.strip().split(" ")
                    new_line= []
                    for i in line:
                        if len(i.strip())!=0:
                            new_line.append(i)
                    result.append(new_line[1:])
                    return result

# result = get_memory_stats("/home/pasindu/Desktop/filename.txt")

def get_swap_stats(filename):
    result = [['kbswpfree', 'kbswpused',  '%swpused',  'kbswpcad',   '%swpcad']]
    if os.path.isfile(filename):
        with open(filename) as f:
            content = f.readlines()
            for line in content:
                if(line.startswith("Average")):
                    line = line.strip().split(" ")
                    new_line= []
                    for i in line:
                        if len(i.strip())!=0:
                            new_line.append(i)
                    result.append(new_line[1:])
                    return result

# result = get_swap_stats("/home/pasindu/Desktop/filename.txt")


def get_io_stats(filename):
    result = [['tps',      'rtps',      'wtps',   'bread/s',   'bwrtn/s']]
    if os.path.isfile(filename):
        with open(filename) as f:
            content = f.readlines()
            for line in content:
                if(line.startswith("Average")):
                    line = line.strip().split(" ")
                    new_line= []
                    for i in line:
                        if len(i.strip())!=0:
                            new_line.append(i)
                    result.append(new_line[1:])
                    return result


# result = get_io_stats("/home/pasindu/Desktop/filename.txt")


def get_inode_stats(filename):
    result = [['dentunusd',   'file-nr',  'inode-nr',    'pty-nr']]
    if os.path.isfile(filename):
        with open(filename) as f:
            content = f.readlines()
            for line in content:
                if(line.startswith("Average")):
                    line = line.strip().split(" ")
                    new_line= []
                    for i in line:
                        if len(i.strip())!=0:
                            new_line.append(i)
                    result.append(new_line[1:])
                    return result


# result = get_inode_stats("/home/pasindu/Desktop/filename.txt")

def get_context_switch_stats(filename):
    result = [['proc/s',   'cswch/s']]
    if os.path.isfile(filename):
        with open(filename) as f:
            content = f.readlines()
            for line in content:
                if(line.startswith("Average")):
                    line = line.strip().split(" ")
                    new_line= []
                    for i in line:
                        if len(i.strip())!=0:
                            new_line.append(i)
                    result.append(new_line[1:])
                    return result


# result = get_context_switch_stats("/home/pasindu/Desktop/filename.txt")

def get_queue_length_stats(filename):
    result = [['runq-sz',  'plist-sz',   'ldavg-1',   'ldavg-5',  'ldavg-15',   'blocked']]
    if os.path.isfile(filename):
        with open(filename) as f:
            content = f.readlines()
            for line in content:
                if(line.startswith("Average")):
                    line = line.strip().split(" ")
                    new_line= []
                    for i in line:
                        if len(i.strip())!=0:
                            new_line.append(i)
                    result.append(new_line[1:])
                    return result


# result = get_queue_length_stats("/home/pasindu/Desktop/filename.txt")

def allZero(array):
    for i in array[2:]:
        if(str(i.strip())!='0.00'):
            return False
    return True

def get_network_stats(filename):
    result = [['IFACE',   'rxpck/s',   'txpck/s',    'rxkB/s',    'txkB/s',   'rxcmp/s' ,  'txcmp/s' , 'rxmcst/s',   '%ifutil']]
    if os.path.isfile(filename):
        with open(filename) as f:
            content = f.readlines()
            for line in content:
                if(line.startswith("Average") and not line.__contains__("IFACE")):
                    line = line.strip().split(" ")
                    new_line= []
                    for i in line:
                        if len(i.strip())!=0:
                            new_line.append(i)
                    if(allZero(new_line)):
                        continue

                    else:
                        result.append(new_line[2:])

                        return result


# result = get_network_stats("/home/pasindu/Desktop/filename.txt")