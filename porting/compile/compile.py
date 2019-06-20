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
        cin, cout, pad, kernel = \
            int(insn[1]), int(insn[2]), int(insn[4]), int(insn[3])
        return opcode * 2**27 + cin * 2**16 + cout * 2**5 + pad * 2**3 + kernel
    elif op == 'cfgcvif':
        opcode = 12
        height, width = int(insn[1]), int(insn[2])
        return opcode * 2**27 + height * 2**13 + width
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
        broadcast = 1 if insn[1] == 'broadcast' else 0
        peid = 0 if insn[1] == 'broadcast' else int(insn[1])
        return opcode * 2**27 + broadcast * 2**8 + peid
    elif op == 'cvcfgext':
        opcode = 17
        assert insn[1] == 'hw' or insn[1] == 'io'
        sel = 0 if insn[1] == 'hw' else 1
        ext1, ext2 = int(insn[2]), int(insn[3])
        return opcode * 2**27 + sel * 2**26 + ext1 * 2**13 + ext2
    elif op == 'cvcfgori':
        opcode = 18
        assert insn[1] == 'hw' or insn[1] == 'io'
        sel = 0 if insn[1] == 'hw' else 1
        ori_width = 13
        ori1, ori2 = int(insn[2]), int(insn[3])
        ori1 = ori1 if ori1 >= 0 else 2**ori_width + ori1
        ori2 = ori2 if ori2 >= 0 else 2**ori_width + ori2
        return opcode * 2**27 + sel * 2**26 + ori1 * 2**13 + ori2
    elif op == 'cvlifp':
        opcode = 19
        return opcode * 2**27
    elif op == 'cvlwp':
        opcode = 20
        return opcode * 2**27
    elif op == 'cvsofp':
        opcode = 21
        return opcode * 2**27
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
        print("Usage: python compile.py <desc> <asm output> <insn output>")
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

    ifbase = [wbase[-1] + ifsize * 2 * i for i in range(3)]
    ifid = [i for i in range(3)]
    wid = 0

    print(ifbase)
    print(wbase)

    C, H, W = 0, 0, 0

    Hp, Wp, Op, Ip = 12, 12, 12, 12

    program.append(
        ['// start of calculation, input feature @{}'.format(ifbase[0])])

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
                if len(param) == 3:  # no padding
                    param.append(0)
                I, O, K, pad = param
                program.append(['cfgl', 'conv', *prop])
                program.append(['cfgcv', *param])
                program.append(['cfgcvif', H, W])
                program.append(['cvaif', ifbase[0]])
                program.append(['cvaw', wbase[wid]])
                program.append(['cvaof', ifbase[1]])
                program.append(['cvselpe', 0])
                Hext, Wext = min(H, Hp), min(W, Wp)
                for s in range(0, O, Op):
                    Oext = min(Op, O-s)
                    program.append(['cvcfgori', 'io', 0, s])
                    program.append(['cvcfgext', 'io', 0, min(O, s+Op)-s])
                    program.append(['cvlwp'])
                    for h in range(-pad, H+pad, Hp-K+1):
                        if H + pad - h < K:
                            break
                        for w in range(-pad, W+pad, Wp-K+1):
                            if W + pad - w < K:
                                break
                            Oori, Hori, Wori = s, h, w
                            program.append(['cvcfgori', 'hw', h, w])
                            program.append(['cvcfgext', 'hw',
                                            min(H+pad-h, Hp), min(W+pad-w, Wp)])
                            for m in range(0, I, Ip):
                                program.append(['cvcfgori', 'io', m, s])
                                program.append(['cvcfgext', 'io',
                                                min(I, m+Ip)-m, min(O, s+Op)-s])
                                program.append(['cvlifp'])
                            program.append(['cvsofp'])
                H, W = H - K + 1 + 2*pad, W - K + 1 + 2*pad
                ifbase[0], ifbase[1] = ifbase[1], ifbase[0]
                wid += 1
            elif layer_type == 'maxpool':
                program.append(['// maxpool'])
                program.append(['cfgl', 'mp'])
                program.append(['cfgcv', O, O, 0, 0])
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
