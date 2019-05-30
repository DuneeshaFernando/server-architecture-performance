import os

def remove_empty_items(array):
    result = []
    for i in array:
        if(len(i.strip())!=0):
            result.append(i)
    return result

def get_stats(filename):
    headers = []
    values = []
    if os.path.isfile(filename):
        with open(filename) as f:
            content = f.readlines()
            content = content[5:]
            for line in content:
                line = line.replace("\n", "")
                if(len(line.strip())!= 0 and not line.__contains__("seconds time elapsed")):
                    line = line.replace("not counted", "not_counted")
                    line = line.replace("not supported", "not_supported")
                    items = remove_empty_items(line.split(" "))
                    headers.append(items[1])
                    values.append(items[0])
    return [headers, values]

# result = get_stats("/home/pasindu/Desktop/filename.txt")