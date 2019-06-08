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

    H, W, I, O, K = 32, 32, 2, 32, 3
    a = torch.randn(1, I, H, W) / 4
    # b = torch.randn(O, I, K, K) / 4
    b = torch.randn(0)
    # c = torch.nn.functional.conv2d(a, b)
    c = torch.nn.functional.max_pool2d(a, kernel_size=2)

    print(a.shape)
    print(b.shape)
    print(c.shape)

    a = to_fixed16(a.data.numpy().flatten())
    # b = to_fixed16(b.data.numpy().flatten())
    b = b.data.numpy().flatten()
    c = to_fixed16(c.data.numpy().flatten())

    print(a, b, c)

    np.save('convtest.npy', b)

    with open('../mem/din.mem', 'w') as f:
        f.write('@{:x}\n'.format(int(sys.argv[1])))
        for x in a:
            f.write('{:04x}\n'.format(x))
        f.write('@{:x}\n'.format(ext_mem_size-1))

    with open('../mem/golden.mem', 'w') as f:
        for x in c:
            f.write('{:04x}\n'.format(x))
        f.write('@{:x}\n'.format(32768-1))
