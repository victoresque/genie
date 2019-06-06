import sys
import numpy as np


if __name__ == '__main__':
    program = []
    wbase = [0]
    ifsize = 0
    C, H, W = 0, 0, 0
    with open(sys.argv[1], 'r') as f:
        for line in f:
            line = line.split()
            layer_type = line[0]

            if layer_type == 'fc':
                prop = line[2:]
                param = [int(p) for p in line[1].split(',')]
                wsize = np.prod(param) + (param[1] if 'bias' in prop else 0)
                ifsize = max(ifsize, param[0], param[1])
                wbase.append(wbase[-1] + wsize)
            elif layer_type == 'ifdim':
                param = [int(p) for p in line[1].split(',')]
                C, H, W = param[0], param[1], param[2]
            elif layer_type == 'conv':
                prop = line[2:]
                param = [int(p) for p in line[1].split(',')]
                I, O, K = param[0], param[1], param[2]
                assert C == I
                wsize = I * O * K * K + (O if 'bias' in prop else 0)
                wbase.append(wbase[-1] + wsize)
                ifsize = max(ifsize, C * H * W)
                C, H, W = O, H-K+1, W-K+1
                ifsize = max(ifsize, C * H * W)
            elif layer_type == 'maxpool':
                ifsize = max(ifsize, C * H * W)
                C, H, W = C, H//2, W//2
                ifsize = max(ifsize, C * H * W)
            elif layer_type == 'flatten':
                pass
            else:
                assert False

    ifbase = [wbase[-1] + ifsize * i for i in range(3)]
    ifid = [i for i in range(3)]
    wid = 0

    print(ifbase)
    print(wbase)

    with open(sys.argv[1], 'r') as f:
        for line in f:
            line = line.split()
            layer_type = line[0]

            if layer_type == 'fc':
                prop = line[2:]
                param = line[1].split(',')
                program.append(['cfgl', 'fc', *prop])
                program.append(['cfgfc', *param])
                program.append(['fclif', ifbase[0]])
                program.append(['fclw', wbase[wid]])
                program.append(['fcsof', ifbase[1]])
                ifbase[0], ifbase[1] = ifbase[1], ifbase[0]
                wid += 1
            elif layer_type == 'ifdim':
                pass
            elif layer_type == 'conv':
                wid += 1
            elif layer_type == 'maxpool':
                program.append(['cfgl', 'mp'])
                program.append(['mplif', ifbase[0]])
                program.append(['mpsof', ifbase[1]])
                ifbase[0], ifbase[1] = ifbase[1], ifbase[0]
            elif layer_type == 'flatten':
                pass
            else:
                assert False

    program.append(['eoc'])

    with open(sys.argv[2], 'w') as f:
        for line in program:
            line = [str(x) for x in line]
            f.write(', '.join(line) + '\n')
