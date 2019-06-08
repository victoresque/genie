import sys


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
    elif op == 'mplif':
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
    program = []
    with open(sys.argv[1], 'r') as f:
        for line in f:
            if line[0] != '/':
                line = line.split(',')
                line = [x.strip() for x in line]
                program.append(line)

    with open('../mem/insn.mem', 'w') as f:
        insn_mem_size = 8192
        f.write('@0\n')
        for insn in program:
            f.write('{:032b}\n'.format(assemble(insn)))
        f.write('@{:x}\n'.format(insn_mem_size-1))
