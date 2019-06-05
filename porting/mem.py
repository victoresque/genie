import numpy as np


if __name__ == '__main__':
    S, M, F = 1, 5, 10
    ext_mem_size = 67108864

    model = np.load('model.npy')
    model = (model * 2**F).astype(np.int32)

    print(model)
    model[model < 0] += 2**16
    model = model.astype(np.uint16)

    with open('../mem/model.mem', 'w') as f:
        f.write('@0\n')
        for p in model:
            f.write('{:04x}\n'.format(p))
        f.write('@{:x}\n'.format(ext_mem_size-1))
