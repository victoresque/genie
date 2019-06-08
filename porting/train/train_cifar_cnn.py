import torch
import torch.nn as nn
from torch.optim import SGD, Adam
import torchvision
from torchvision import datasets, transforms
from tqdm import tqdm
import numpy as np


def train_cifar10(T):
    class Flatten(nn.Module):
        def forward(self, x):
            x = x.view(x.size()[0], -1)
            return x
    model = nn.Sequential(
        nn.Conv2d(3, 16, 3),
        nn.ReLU(inplace=True),
        nn.MaxPool2d(2),
        nn.Conv2d(16, 32, 3),
        nn.ReLU(inplace=True),
        nn.MaxPool2d(2),
        nn.Conv2d(32, 64, 3),
        nn.ReLU(inplace=True),
        nn.Conv2d(64, 10, 3),
        Flatten(),
        nn.Linear(40, 10)
    )
    optimizer = Adam(model.parameters(), lr=1e-3)

    for _ in range(T):
        total_loss = 0
        correct = 0
        for img, label in tqdm(train_loader):
            optimizer.zero_grad()
            output = model(img)
            loss = nn.functional.cross_entropy(output, label)
            loss.backward()
            optimizer.step()

            if (output.argmax() == label):
                correct = correct + 1
            total_loss = total_loss + loss.item()
        print('loss:    ', total_loss / len(train_loader))
        print('acc:     ', correct / len(train_loader))

        correct = 0
        for img, label in tqdm(test_loader):
            output = model(img)
            if (output.argmax() == label):
                correct = correct + 1
        print('val_acc: ', correct / len(test_loader))

    return model


if __name__ == '__main__':
    cifar_data = datasets.CIFAR10(
        '../data', train=True, download=True, transform=transforms.ToTensor())

    print(len(cifar_data))

    ntrain = 30000
    ntest = 3000
    train_data, test_data, _ = torch.utils.data.random_split(
        cifar_data, [ntrain, ntest, 50000-ntrain-ntest])

    train_loader = torch.utils.data.DataLoader(
        train_data, batch_size=1, shuffle=False, num_workers=1)
    test_loader = torch.utils.data.DataLoader(
        test_data, batch_size=1, shuffle=False, num_workers=1)

    T = 3
    model = train_cifar10(T)

    all_param = np.zeros((0, ))
    for p in model.parameters():
        tmp = p.data.numpy().flatten()
        all_param = np.concatenate((all_param, p.data.numpy().flatten()))

    all_param = all_param.flatten()
    np.save('../model/cifar_cnn.npy', all_param)
