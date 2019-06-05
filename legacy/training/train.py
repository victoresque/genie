import torch
import torch.nn as nn
from torch.optim import SGD
import torchvision
from torchvision import datasets, transforms
from tqdm import tqdm
import numpy as np
from mynn import MyModel, MyCNNModel


def train_pytorch():
    model = nn.Sequential(
        nn.Linear(784, 32),
        nn.ReLU(inplace=True),
        nn.Linear(32, 10)
    )
    optimizer = SGD(model.parameters(), lr=1e-1)
    while True:
        total_loss = 0
        correct = 0
        for img, label in tqdm(train_loader):
            target = torch.zeros(1, 10)
            target[0, label] = 1
            img = img.view(1, -1)

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
            img = img.view(1, -1)

            output = model(img)

            if (output.argmax() == target.argmax()):
                correct = correct + 1

        print('val_acc: ', correct / len(test_loader))


def train_pytorch_cnn():
    model = nn.Sequential(
        nn.Conv2d(1, 2, 3),
        nn.ReLU(inplace=True),
        nn.MaxPool2d(2),
        nn.Conv2d(2, 4, 3),
        nn.ReLU(inplace=True),
        nn.MaxPool2d(2),
        nn.Conv2d(4, 8, 3),
        nn.ReLU(inplace=True),
        nn.Conv2d(8, 10, 3)
    )
    optimizer = SGD(model.parameters(), lr=1e-1)
    while True:
        total_loss = 0
        correct = 0
        for img, label in tqdm(train_loader):
            target = torch.zeros(1, 10)
            target[0, label] = 1
            target = target.view(1, 10, 1, 1)

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


def train_mynn():
    mymodel = MyModel()
    while True:
        total_loss = 0
        correct = 0
        for img, label in tqdm(train_loader):
            target = torch.zeros(10).data.numpy()
            target[label] = 1
            img = img.view(-1).data.numpy()

            output, loss = mymodel.forward(img, target)
            mymodel.backward()

            if (output.argmax() == target.argmax()):
                correct = correct + 1
            total_loss = total_loss + loss

        print('loss:    ', total_loss / len(train_loader))
        print('acc:     ', correct / len(train_loader))

        correct = 0
        for img, label in tqdm(test_loader):
            target = torch.zeros(10).data.numpy()
            target[label] = 1
            img = img.view(-1).data.numpy()

            output, _ = mymodel.forward(img, target)

            if (output.argmax() == target.argmax()):
                correct = correct + 1

        print('val_acc: ', correct / len(test_loader))


def train_mycnn():
    mymodel = MyCNNModel()
    while True:
        total_loss = 0
        correct = 0
        for img, label in tqdm(train_loader):
            target = torch.zeros(10).data.numpy()
            target[label] = 1
            img = img.view(28, 28, 1).data.numpy()

            output, loss = mymodel.forward(img, target)
            mymodel.backward()

            target = np.reshape(target, output.shape)
            if (output.argmax() == target.argmax()):
                correct = correct + 1
            total_loss = total_loss + loss

        print('loss:    ', total_loss / len(train_loader))
        print('acc:     ', correct / len(train_loader))

        correct = 0
        for img, label in tqdm(test_loader):
            target = torch.zeros(10).data.numpy()
            target[label] = 1
            img = img.view(28, 28, 1).data.numpy()

            output, _ = mymodel.forward(img, target)

            target = np.reshape(target, output.shape)
            if (output.argmax() == target.argmax()):
                correct = correct + 1

        print('val_acc: ', correct / len(test_loader))


if __name__ == '__main__':
    mnist_data = datasets.MNIST(
        './data', train=True, download=True, transform=transforms.ToTensor())

    ntrain = 50
    ntest = 50
    train_data, test_data, _ = torch.utils.data.random_split(
        mnist_data, [ntrain, ntest, 60000-ntrain-ntest])

    train_loader = torch.utils.data.DataLoader(
        train_data, batch_size=1, shuffle=False, num_workers=1)
    test_loader = torch.utils.data.DataLoader(
        test_data, batch_size=1, shuffle=False, num_workers=1)

    # train_pytorch()
    # train_mynn()

    # train_pytorch_cnn()
    train_mycnn()
