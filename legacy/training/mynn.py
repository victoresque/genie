import numpy as np
np.set_printoptions(precision=2)


class MyModel:
    def __init__(self):
        self.lr = 1e-1
        self.sequential = [
            Linear(784, 32),
            ReLU(),
            Linear(32, 10)
        ]
        self.loss = MSE()

    def forward(self, input, target):
        output = input
        for layer in self.sequential:
            output = layer.forward(output)
        return output, self.loss.forward(output, target)

    def backward(self):
        error = self.loss.backward()
        for layer in reversed(self.sequential):
            error = layer.backward(error, self.lr)


class MyCNNModel:
    def __init__(self):
        self.lr = 1e-1
        self.sequential = [
            Conv2d(3, 1, 2),
            ReLU(),
            MaxPool2d(),
            Conv2d(3, 2, 4),
            ReLU(),
            MaxPool2d(),
            Conv2d(3, 4, 8),
            ReLU(),
            Conv2d(3, 8, 10),
        ]
        self.loss = MSE()

    def forward(self, input_, target):
        output = input_
        for layer in self.sequential:
            output = layer.forward(output)
        return output, self.loss.forward(output, target)

    def backward(self):
        error = self.loss.backward()
        for layer in reversed(self.sequential):
            error = layer.backward(error, self.lr)


class Conv2d_2:
    def __init__(self, K, I, O, stride):
        self.K = K
        self.I = I
        self.O = O
        self.stride = stride
        self.weight = np.random.randn(O, K, K, I) / np.sqrt(K * K * I)
        self.z = None
        self.a = None

    def forward(self, input):
        self.z = input
        H, W, K, I, O = input.shape[0], input.shape[1], self.K, self.I, self.O
        strd = self.stride
        output = np.zeros(((H-K)//strd+1, (W-K)//strd+1, O))
        for h in range(K//2, H-K//2, strd):
            for w in range(K//2, W-K//2, strd):
                h0 = h-K//2
                w0 = w-K//2
                block = input[h0:h0+K, w0:w0+K, :]
                for o in range(O):
                    s = np.sum(block * self.weight[o, :, :, :])
                    output[h0//strd, w0//strd, o] += s
        self.a = output
        return output

    def backward(self, error, lr):
        HI, WI, I = self.z.shape[0], self.z.shape[1], self.I
        HO, WO, O = self.a.shape[0], self.a.shape[1], self.O
        K, strd = self.K, self.stride
        gradient = np.zeros((O, K, K, I))
        z_error = np.zeros((HI, WI, I))
        for ki in range(K):
            for kj in range(K):
                for o in range(O):
                    zsub = self.z[ki:ki+HO*strd:strd, kj:kj+WO*strd:strd, :]
                    esub = error[:, :, o:o+1]
                    gsub = zsub * esub
                    gsub = np.sum(gsub, (0, 1))
                    gradient[o, ki, kj, :] = gradient[o, ki, kj, :] + gsub
        for o in range(O):
            wsub = self.weight[o, :, :, :]
            np.rot90(wsub, k=2)
            adil = np.zeros((1+(HO-1)*strd, 1+(WO-1)*strd, 1))
            for h in range(HO):
                for w in range(WO):
                    adil[h*strd, w*strd, 0] = self.a[h, w, o]
            adil = np.pad(adil, ((K-1, K-1), (K-1, K-1), (0, 0)), 'constant',
                          constant_values=0)
            for h in range(adil.shape[0]-K):
                for w in range(adil.shape[1]-K):
                    asub = adil[h:h+K, w:w+K]
                    zesub = wsub * asub
                    z_error[h, w, :] = z_error[h, w, :] + np.sum(zesub)
        self.weight = self.weight - lr * gradient
        return z_error


class Conv2d:
    def __init__(self, K, I, O):
        self.K = K
        self.I = I
        self.O = O
        self.weight = np.random.randn(O, K, K, I) * np.sqrt(2 / (K * K * O))
        self.z = None
        self.a = None

    def forward(self, input_):
        self.z = input_
        H, W, K, I, O = input_.shape[0], input_.shape[1], self.K, self.I, self.O
        output = np.zeros((H-K+1, W-K+1, O))
        for h in range(0, H-K+1):
            for w in range(0, W-K+1):
                psum = np.sum(input_[np.newaxis, h:h+K, w:w + K, :]
                              * self.weight, (1, 2, 3))
                output[h, w, :] += psum
        self.a = output
        return output

    def backward(self, error, lr):
        HI, WI, I = self.z.shape[0], self.z.shape[1], self.I
        HO, WO, O = self.a.shape[0], self.a.shape[1], self.O
        K = self.K
        gradient = np.zeros((O, K, K, I))
        z_error = np.zeros((HI, WI, I))
        for ki in range(K):
            for kj in range(K):
                for o in range(O):
                    gradient[o, ki, kj, :] += \
                        np.sum(self.z[ki:ki+HO, kj:kj+WO, :] * error[:, :, o:o+1],
                               (0, 1))
        for o in range(O):
            wsub = self.weight[o, :, :, :]
            wsub = np.rot90(wsub, k=2)
            apad = self.a[:, :, o]
            apad = np.pad(apad, ((K-1, K-1), (K-1, K-1)),
                          'constant', constant_values=0)
            for h in range(apad.shape[0]-K+1):
                for w in range(apad.shape[1]-K+1):
                    asub = apad[h:h+K, w:w+K, np.newaxis]
                    zesub = wsub * asub
                    z_error[h, w, :] += np.sum(zesub, (0, 1))
        self.weight = self.weight - lr * gradient
        return z_error


class MaxPool2d:
    def __init__(self):
        self.z = None
        self.mask = None
        self.odd = None

    def forward(self, x):
        self.z = x
        self.odd = x.shape[0] % 2
        x = x[:x.shape[0]-self.odd, :x.shape[1]-self.odd, :]
        x_patches = x.reshape(x.shape[0]//2, 2, x.shape[1]//2, 2, x.shape[2])
        out = x_patches.max(axis=1).max(axis=2)
        x[0::2, 0::2, :] += 1e-7
        x[0::2, 1::2, :] += 2e-7
        x[0::2, 0::2, :] += -1e-7
        x[1::2, 1::2, :] += -2e-7
        self.mask = np.isclose(x, np.repeat(
            np.repeat(out, 2, axis=0), 2, axis=1)).astype(int)
        return out

    def backward(self, error, lr):
        error = np.repeat(np.repeat(error, 2, axis=0), 2, axis=1)
        error = error[:self.mask.shape[0], :self.mask.shape[1], :]
        zerror = self.mask * error
        zerror = np.pad(zerror, ((0, self.odd), (0, self.odd), (0, 0)),
                        mode='constant', constant_values=0)
        return zerror


class Linear:
    def __init__(self, in_features, out_features):
        self.in_features = in_features
        self.out_features = out_features
        self.weight = np.random.randn(
            in_features, out_features) / np.sqrt(in_features)
        self.z = None
        self.a = None

    def forward(self, input):
        self.z = input
        self.a = np.matmul(input, self.weight)
        return self.a

    def backward(self, error, lr):
        gradient = np.matmul(np.expand_dims(self.z, 1),
                             np.expand_dims(error, 0))
        z_error = np.matmul(error, self.weight.T)

        self.weight = self.weight - lr * gradient
        return z_error


class ReLU:
    def __init__(self):
        self.z = None
        self.a = None

    def forward(self, input):
        self.z = input
        self.a = self.z
        self.a[self.a < 0] = 0
        return self.a

    def backward(self, error, lr):
        error[self.z < 0] = 0
        return error


class MSE:
    def __init__(self):
        self.z = None
        self.target = None

    def forward(self, input, target):
        self.z = input
        self.target = target
        return np.mean(np.square(target - input))

    def backward(self):
        return 2 * (self.z - self.target) / self.z.size
