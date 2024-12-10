import numpy as np

def bilinear_interpolation(a1, a2, a3, a4, dx, dy):
    """
    Perform bilinear interpolation.
    a1, a2, a3, a4: Values at the corners
    dx, dy: Fractional offsets (0 <= dx, dy <= 1)
    Returns the interpolated value.
    """
    v1 = a1 * (1 - dx) + a3 * dx
    v2 = a2 * (1 - dx) + a4 * dx
    return v1 * (1 - dy) + v2 * dy

def downsample(ifmap, stride, hout, hin):
    """
    Downsample the input feature map using bilinear interpolation.
    ifmap: Input feature map (numpy array of shape [hin, hin])
    stride: Stride value
    hout: Output feature map dimension
    hin: Input feature map dimension
    Returns the downsampled output feature map.
    """
    ofmap = np.zeros((hout, hout), dtype=np.float32)
    
    for i in range(hout):
        for j in range(hout):
            floor_ph = int(np.floor(stride * i))
            ceil_ph = min(int(np.ceil(stride * i)), hin - 1)
            floor_pw = int(np.floor(stride * j))
            ceil_pw = min(int(np.ceil(stride * j)), hin - 1)
            
            a1 = ifmap[ceil_ph, ceil_pw]
            a2 = ifmap[ceil_ph, floor_pw]
            a3 = ifmap[floor_ph, ceil_pw]
            a4 = ifmap[floor_ph, floor_pw]
            
            dx = stride * j - floor_pw
            dy = stride * i - floor_ph
            
            ofmap[i, j] = bilinear_interpolation(a1, a2, a3, a4, dx, dy)
    
    return ofmap

# Parameters
stride = 1.444
hin = 27
hout = 19

# Create a sample input feature map
ifmap = np.fromfunction(lambda i, j: (i + j) % 256, (hin, hin), dtype=np.uint8)

# Perform downsampling
ofmap = downsample(ifmap, stride, hout, hin)

# Display results
print("Input Feature Map:")
print(ifmap)

print("\nDownsampled Output Feature Map:")
print(np.round(ofmap).astype(np.uint8))  # Round to nearest integer and cast to uint8 for display