import sys
import numpy as np
import torch


def to_fixed16(a):
    S, M, F = 1, 5, 10
    a = np.round(a * 2**F).astype(np.int32)
    a[a < 0] += 2**16
    a = a.astype(np.uint16)
    return a


if __name__ == '__main__':
    ext_mem_size = 67108864

    H, W, I, O, K = 40, 40, 64, 32, 3
    a = torch.randn(1, I, H, W) / 2
    b = torch.randn(O, I, K, K) / 2
    c = torch.nn.functional.conv2d(a, b)

    print(a.shape)
    print(b.shape)
    print(c.shape)

    a = to_fixed16(a.data.numpy().flatten())
    b = to_fixed16(b.data.numpy().flatten())
    c = to_fixed16(c.data.numpy().flatten())

    print(a, b, c)

    with open('./mem/a.mem', 'w') as f:
        for x in a:
            f.write('{:04x}\n'.format(x))
        f.write('@{:x}\n'.format(32768-1))

    with open('./mem/b.mem', 'w') as f:
        for x in b:
            f.write('{:04x}\n'.format(x))
        f.write('@{:x}\n'.format(32768-1))

    with open('./mem/c.mem', 'w') as f:
        for x in c:
            f.write('{:04x}\n'.format(x))
        f.write('@{:x}\n'.format(32768-1))
