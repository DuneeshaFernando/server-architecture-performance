import os


latencies = []
with open("concrete.txt") as f:
    content = f.readlines()
    results = []
    for c in content:
        if not (c.count(":")==2 and c.count(".")==8):
            results.append(c)

    f = open('concrete_new.txt', 'w')
    for ele in results:
        f.write(ele)
    f.close()