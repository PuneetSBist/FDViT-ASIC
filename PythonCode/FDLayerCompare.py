import torch
import torch.nn as nn
import numpy as np
import math
from einops import rearrange
import torch.nn.functional as F
import time
from FDViTInfer import enable_cuda

class FDViTPooling(nn.Module):
    def __init__(self, out_size):
        #super().__init__()
        super(FDViTPooling, self).__init__()
        d = torch.linspace(-1, 1, out_size)
        meshx, meshy = torch.meshgrid((d, d))
        self.grid = torch.stack((meshy, meshx), 2)

    def forward(self, x):
        h = w = int(math.sqrt(x.shape[1]))
        y = rearrange(x, 'b (h w) c -> b c h w', h=h, w=w)
        grid = self.grid.expand(y.shape[0], -1, -1, -1)
        z = F.grid_sample(y, grid.to(y.device).type_as(y),align_corners=True)
        return z


class TwoDAvgPooling(nn.Module):
    def __init__(self, stride=2):
        super(TwoDAvgPooling, self).__init__()
        self.avgpool2d = nn.AvgPool2d(kernel_size=2, stride=stride)

    def forward(self, x):
        # Using MaxPool2d with a 2x2 kernel and stride 2 (downsampling by 2)
        h = w = int(math.sqrt(x.shape[1]))
        y = rearrange(x, 'b (h w) c -> b c h w', h=h, w=w)
        z = self.avgpool2d(x)
        return z


class TwoDPooling(nn.Module):
    def __init__(self, stride=2):
        super(TwoDPooling, self).__init__()
        self.maxpool2d = nn.MaxPool2d(kernel_size=2, stride=stride)

    def forward(self, x):
        # Using MaxPool2d with a 2x2 kernel and stride 2 (downsampling by 2)
        h = w = int(math.sqrt(x.shape[1]))
        y = rearrange(x, 'b (h w) c -> b c h w', h=h, w=w)
        z = self.maxpool2d(x)
        return z


def pooling_latency(device, name, pooler, input, itera, prin=True):
    pooler.to(device)
    input_d = input.to(device)
    start_time = time.perf_counter()

    for _ in range(itera):
        pooler(input_d)
    end_time = time.perf_counter()
    if prin:
        print(f"{name} Execution time: {end_time - start_time} seconds")


def run_FD_comparison(enable_gpu, itera=1000):
    device = enable_cuda(no_cuda=not enable_gpu)

    # Create a tensor of shape (729, 64) where each row starts from 0 to 63
    #simple = torch.arange(64*3).reshape(64, 3).float()
    simple = torch.randint(0, 11, (64, 3)).float()
    simple = simple.unsqueeze(0)
    FDLayer0 = FDViTPooling(6)
    """
    normPool1 = TwoDPooling(1)
    normPool2 = TwoDPooling(2)

    pooling_latency("FD", FDLayer0, simple, 128)
    pooling_latency("Pool1", normPool1, simple, 128)
    pooling_latency("Pool2", normPool2, simple, 128)
    """

    FDLayer1 = FDViTPooling(19)

    normPool1 = TwoDPooling(1)
    normPool2 = TwoDPooling(2)
    avgPool1 = TwoDAvgPooling(1)
    avgPool2 = TwoDAvgPooling(2)

    """
    tensor2 = torch.arange(92*361).reshape(361, 92).float()
    tensor2 = tensor2.unsqueeze(0)
    FDLayer2 = FDViTPooling(14)

    tensor3 = torch.arange(126*196).reshape(196, 126).float()
    tensor3 = tensor3.unsqueeze(0)
    FDLayer3 = FDViTPooling(10)

    tensor4 = torch.arange(184*100).reshape(100, 184).float()
    tensor4 = tensor4.unsqueeze(0)
    FDLayer4 = FDViTPooling(7)
    """

    tensor1 = torch.arange(729 * 64).reshape(729, 64).float()
    tensor1 = tensor1.unsqueeze(0)
    pooling_latency(device, "FD1", FDLayer1, tensor1, itera)

    tensor1 = torch.arange(729 * 64).reshape(729, 64).float()
    tensor1 = tensor1.unsqueeze(0)
    pooling_latency(device, "AvgPoolS1", avgPool1, tensor1, itera)

    tensor1 = torch.arange(729 * 64).reshape(729, 64).float()
    tensor1 = tensor1.unsqueeze(0)
    pooling_latency(device, "AvgPoolS2", avgPool2, tensor1, itera)

    tensor1 = torch.arange(729 * 64).reshape(729, 64).float()
    tensor1 = tensor1.unsqueeze(0)
    pooling_latency(device, "MaxPoolS1", normPool1, tensor1, itera)

    tensor1 = torch.arange(729 * 64).reshape(729, 64).float()
    tensor1 = tensor1.unsqueeze(0)
    pooling_latency(device, "MaxPoolS2", normPool2, tensor1, itera)

    """
    pooling_latency(device, "FD2", FDLayer2, tensor2, itera)
    pooling_latency(device, "FD3", FDLayer3, tensor3, itera)
    pooling_latency(device, "FD4", FDLayer4, tensor4, itera)
    """



