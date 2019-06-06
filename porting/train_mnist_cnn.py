import torch
import torch.nn as nn
from torch.optim import SGD
import torchvision
from torchvision import datasets, transforms
from tqdm import tqdm
import numpy as np


def train(T):
    class Flatten(nn.Module):
        def forward(self, x):
            x = x.view(x.size()[0], -1)
            return x
    model = nn.Sequential(
        nn.Conv2d(1, 16, 3),
        nn.ReLU(inplace=True),
        nn.MaxPool2d(2),
        nn.Conv2d(16, 32, 3),
        nn.ReLU(inplace=True),
        nn.MaxPool2d(2),
        nn.Conv2d(32, 16, 3),
        nn.ReLU(inplace=True),
        Flatten(),
        nn.Linear(144, 10),
    )
    optimizer = SGD(model.parameters(), lr=1e-1)

    for _ in range(T):
        total_loss = 0
        correct = 0
        for img, label in tqdm(train_loader):
            target = torch.zeros(1, 10)
            target[0, label] = 1

            optimizer.zero_grad()
            output = model(img)

            loss = nn.functional.mse_loss(output, target)
            loss.backward()
            optimizer.step()

            if (output.argmax() == target.argmax()):
                correct = correct + 1
            total_loss = total_loss + loss.item()
        print('loss:    ', total_loss / len(train_loader))
        print('acc:     ', correct / len(train_loader))

        correct = 0
        for img, label in tqdm(test_loader):
            target = torch.zeros(1, 10)
            target[0, label] = 1
            target = target.view(1, 10, 1, 1)

            output = model(img)

            if (output.argmax() == target.argmax()):
                correct = correct + 1
        print('val_acc: ', correct / len(test_loader))

    return model


if __name__ == '__main__':
    mnist_data = datasets.MNIST(
        './data', train=True, download=True, transform=transforms.ToTensor())

    ntrain = 10000
    ntest = 1000
    train_data, test_data, _ = torch.utils.data.random_split(
        mnist_data, [ntrain, ntest, 60000-ntrain-ntest])

    train_loader = torch.utils.data.DataLoader(
        train_data, batch_size=1, shuffle=False, num_workers=1)
    test_loader = torch.utils.data.DataLoader(
        test_data, batch_size=1, shuffle=False, num_workers=1)

    T = 5
    model = train(T)

    all_param = np.zeros((0, ))
    for p in model.parameters():
        tmp = p.data.numpy().flatten()
        all_param = np.concatenate((all_param, p.data.numpy().flatten()))

    all_param = all_param.flatten()
    np.save('model_cnn.npy', all_param)
