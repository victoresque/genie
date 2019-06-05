import torch
import torchvision
import numpy as np
from torchvision import datasets, transforms


if __name__ == '__main__':
    mnist_data = datasets.MNIST(
        './data', train=True, download=True, transform=transforms.ToTensor())

    data_loader = torch.utils.data.DataLoader(
        mnist_data, batch_size=1, shuffle=True, num_workers=1)

    for img, label in data_loader:
        img = img.data.numpy().flatten()
        label = label.data.numpy().flatten()
        break

    S, M, F = 1, 5, 10
    ext_mem_size = 67108864
    img = (img * 2**F).astype(np.int32)

    print(img)
    img[img < 0] += 2**16
    img = img.astype(np.uint16)

    with open('../mem/din.mem', 'w') as f:
        f.write('@{:x}\n'.format(26506))
        for x in img:
            f.write('{:04x}\n'.format(x))
        f.write('@{:x}\n'.format(ext_mem_size-1))

    print(label)
