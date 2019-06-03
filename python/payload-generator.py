import sys


def create_string(msg_size_in_bytes):
    string = ''
    num_characters = int(msg_size_in_bytes)
    for i in range(num_characters):
        string = string + 'a'

    return string


def generate_payloads(message_sizes):
    payloads = []
    for size in message_sizes:
        payloads.append(create_string(size))
    return payloads


def write_payLoads(message_sizes, payloads):
    for i in range(len(message_sizes)):
        file_name = output_file_root+str(message_sizes[i])
        file = open(file_name, "w")
        file.write(payloads[i])


output_file_root = sys.argv[1]
message_sizes= [102400, 51200, 10240, 4096, 2048, 1024, 500, 100, 50, 10, 1]
payloads = generate_payloads(message_sizes)
write_payLoads(message_sizes, payloads)