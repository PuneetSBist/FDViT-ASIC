import matplotlib.pyplot as plt
import numpy as np

from FDViTInfer import run_model_latency, run_FDVit_Full,run_volo_d4_448_Full
from FDLayerCompare import run_FD_comparison
from ReadLabelAndAccuracy import parse_execution_times
import sys


# Function to redirect print statements to a file
def redirect_print_to_file(file_path, function, enable_gpu):
    # Open the file in write mode
    with open(file_path, 'w') as f:
        # Save the current stdout to restore it later
        original_stdout = sys.stdout
        # Redirect stdout to the file
        sys.stdout = f

        try:
            # Call the function (and pass any arguments or kwargs)
            function(enable_gpu)
        finally:
            # Restore the original stdout
            sys.stdout = original_stdout


def generate_model_latency(enable_gpu = False):
    if enable_gpu:
        for itera in range(5):
            run_model_latency(enable_gpu=True, image_set_count=1000, file_prefix="27Nov\\GPURun" + str(itera))
    else:
        for itera in range(5):
            run_model_latency(enable_gpu=False, image_set_count=1000, file_prefix="27Nov\\CPURun"+str(itera))


def generate_pooling_latency(enable_gpu = False):
    if enable_gpu:
        for _ in range(5):
            run_FD_comparison(enable_gpu=True, itera=1000)
    else:
        for _ in range(5):
            run_FD_comparison(enable_gpu=False, itera=1000)


def get_execution_time():
    cpu_file_path = 'C:\\Users\\bistp\\Downloads\\CLass\\AdvHardML\\HW1_b\\ViT\\model\\28Nov\\CPU_MODEL_LAT.txt'  # Path to your file
    gpu_file_path = 'C:\\Users\\bistp\\Downloads\\CLass\\AdvHardML\\HW1_b\\ViT\\model\\28Nov\\GPU_MODEL_LAT.txt'  # Path to your file
    cpu_execution_times = parse_execution_times(cpu_file_path)
    gpu_execution_times = parse_execution_times(gpu_file_path)
    print("CPU:", cpu_execution_times)
    print("GPU:", gpu_execution_times)

    cpu_file_path = '28Nov\\CPU_POOL_LAT.txt'  # Path to your file
    gpu_file_path = '28Nov\\GPU_POOL_LAT.txt'  # Path to your file
    cpu_execution_times = parse_execution_times(cpu_file_path)
    gpu_execution_times = parse_execution_times(gpu_file_path)
    print("CPU:", cpu_execution_times)
    print("GPU:", gpu_execution_times)


"""
redirect_print_to_file("28Nov\\CPU_MODEL_LAT.txt", generate_model_latency, False)
print("done 1")
redirect_print_to_file("28Nov\\GPU_MODEL_LAT.txt", generate_model_latency, True)
print("done 2")
"""
redirect_print_to_file("28Nov\\CPU_POOL_LAT.txt", generate_pooling_latency, False)
print("done 3")
redirect_print_to_file("28Nov\\GPU_POOL_LAT.txt", generate_pooling_latency, True)
print("done 4")

get_execution_time()

#run_FDVit_Full(enable_gpu=True, file_prefix="")
#run_volo_d4_448_Full(enable_gpu=True, file_prefix="")
