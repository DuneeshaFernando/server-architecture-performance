def write_file(file_path_root, size):
    size = int(size)
    file_path = file_path_root+"/"+str(size)
    content = size*"a"
    f = open(file_path, "w")
    f.write(content)
    f.close()


def get_even_nine_sizes(min_num, max_num):
    return [min_num+ i* (max_num-min_num)/9 for i in range(1, 10)]


file_path_root = "/home/ubuntu/pasindu/file_server"
sizes = (get_even_nine_sizes(0, 1024)) + (get_even_nine_sizes(1024, 10240)) + (get_even_nine_sizes(10240, 102400)) + (get_even_nine_sizes(102400, 1024000))

for size in sizes:
    write_file(file_path_root, size)