import sys
import numpy as np


def assemble(insn):
    op = insn[0]
    if op == 'cfgl':
        opcode = 1
        layer_names = ['', 'fc', 'conv', 'mp']
        layer = layer_names.index(insn[1])

        if insn[1] == 'fc' or insn[1] == 'conv':
            act_names = ['noact', 'relu']
            act = act_names.index(insn[2])
            bias = 0 if insn[3] == 'nobias' else 1
        else:
            act, bias = 0, 0

        return opcode * 2**27 + layer * 2**16 + act * 2**5 + bias
    elif op == 'cfgfc':
        opcode = 2
        cin, cout = int(insn[1]), int(insn[2])
        return opcode * 2**27 + cin * 2**16 + cout * 2**5
    elif op == 'fclif':
        opcode = 3
        addr = int(insn[1])
        return opcode * 2**27 + addr
    elif op == 'fclw':
        opcode = 4
        addr = int(insn[1])
        return opcode * 2**27 + addr
    elif op == 'fcsof':
        opcode = 5
        addr = int(insn[1])
        return opcode * 2**27 + addr
    elif op == 'cfgcv':
        opcode = 11
        cin, cout, kernel = int(insn[1]), int(insn[2]), int(insn[3])
        return opcode * 2**27 + cin * 2**16 + cout * 2**5 + kernel
    elif op == 'cfgcvif':
        opcode = 12
        height, width = int(insn[1]), int(insn[2])
        return opcode * 2**27 + height * 2**16 + width * 2**5
    elif op == 'cvaif':
        opcode = 13
        addr = int(insn[1])
        return opcode * 2**27 + addr
    elif op == 'cvaw':
        opcode = 14
        addr = int(insn[1])
        return opcode * 2**27 + addr
    elif op == 'cvaof':
        opcode = 15
        addr = int(insn[1])
        return opcode * 2**27 + addr
    elif op == 'cvselpe':
        opcode = 16
        peid = int(insn[1])
        return opcode * 2**27 + peid
    elif op == 'cvcfgpe':
        opcode = 17
        Oext, Hext, Wext = int(insn[1]), int(insn[2]), int(insn[3])
        return opcode * 2**27 + Oext * 2**16 + Hext * 2**8 + Wext
    elif op == 'cvlifp':
        opcode = 18
        Hori, Wori = int(insn[1]), int(insn[2])
        return opcode * 2**27 + Hori * 2**8 + Wori
    elif op == 'cvlwp':
        opcode = 19
        Oori = int(insn[1])
        return opcode * 2**27 + Oori * 2**16
    elif op == 'cvsofp':
        opcode = 20
        Oori, Hori, Wori = int(insn[1]), int(insn[2]), int(insn[3])
        return opcode * 2**27 + Oori * 2**16 + Hori * 2**8 + Wori
    elif op == 'mpaif':
        opcode = 28
        addr = int(insn[1])
        return opcode * 2**27 + addr
    elif op == 'mpsof':
        opcode = 29
        addr = int(insn[1])
        return opcode * 2**27 + addr
    elif op == 'eoc':
        opcode = 31
        return opcode * 2**27
    else:
        assert False, op


if __name__ == '__main__':
    if len(sys.argv) != 4:
        print("Usage: python compile.py ../desc/cnn.desc"
              " ../asm/cnn.genie ../../mem/insn.mem")
        exit()

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

    C, H, W = 0, 0, 0

    Hp, Wp, S = 12, 12, 12

    with open(sys.argv[1], 'r') as f:
        for line in f:
            line = line.split()
            layer_type = line[0]

            if layer_type == 'fc':
                program.append(['// fc'])
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
                C, H, W = [int(x) for x in line[1].split(',')]
                O = C
            elif layer_type == 'conv':
                program.append(['// conv'])
                prop = line[2:]
                param = [int(x) for x in line[1].split(',')]
                I, O, K = param
                program.append(['cfgl', 'conv', *prop])
                program.append(['cfgcv', *param])
                program.append(['cfgcvif', H, W])
                program.append(['cvaif', ifbase[0]])
                program.append(['cvaw', wbase[wid]])
                program.append(['cvaof', ifbase[1]])
                program.append(['cvselpe', 0])
                Hext, Wext = min(H, Hp), min(W, Wp)
                for s in range(0, O, S):
                    Oext = min(S, O-s)
                    wloaded = False
                    for h in range(0, H, Hp-K+1):
                        if H - h < K:
                            break
                        for w in range(0, W, Wp-K+1):
                            if W - w < K:
                                break
                            Oori, Hori, Wori = s, h, w
                            program.append(['cvcfgpe', Oext,
                                            min(H, h+Hp)-h, min(W, w+Wp)-w])
                            if not wloaded:
                                program.append(['cvlwp', s])
                                wloaded = True
                            program.append(['cvlifp', Hori, Wori])
                            program.append(['cvsofp', Oori, Hori, Wori])
                H, W = H - K + 1, W - K + 1
                ifbase[0], ifbase[1] = ifbase[1], ifbase[0]
                wid += 1
            elif layer_type == 'maxpool':
                program.append(['// maxpool'])
                program.append(['cfgl', 'mp'])
                program.append(['cfgcv', O, O, 0])
                program.append(['cfgcvif', H, W])
                program.append(['mpaif', ifbase[0]])
                program.append(['mpsof', ifbase[1]])
                H, W = H // 2, W // 2
                ifbase[0], ifbase[1] = ifbase[1], ifbase[0]
            elif layer_type == 'flatten':
                pass
            else:
                assert False

    program.append(
        ['// end of calculation, out feature @{}'.format(ifbase[0])])
    program.append(['eoc'])

    with open(sys.argv[2], 'w') as f:
        for line in program:
            line = [str(x) for x in line]
            f.write(', '.join(line) + '\n')

    program = []
    with open(sys.argv[2], 'r') as f:
        for line in f:
            if line[0] != '/':
                line = line.split(',')
                line = [x.strip() for x in line]
                program.append(line)

    with open(sys.argv[3], 'w') as f:
        insn_mem_size = 8192
        f.write('@0\n')
        for insn in program:
            f.write('{:032b}\n'.format(assemble(insn)))
        f.write('@{:x}\n'.format(insn_mem_size-1))
