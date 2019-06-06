
def assemble(insn):
    op = insn[0]
    if op == 'cfgl':
        opcode = 1
        layer_names = ['', 'fc', 'conv', 'mp']
        layer = layer_names.index(insn[1])

        act_names = ['noact', 'relu']
        act = act_names.index(insn[2])

        bias = 0 if insn[3] == 'nobias' else 1

        return opcode * 2**27 + layer * 2**16 + act * 2**5 + bias
    elif op == 'cfgfc':
        opcode = 2
        cin, cout = int(insn[1]), int(insn[2])
        return opcode * 2**27 + cin * 2**16 + cout * 2**5
    elif op == 'cfgcv':
        opcode = 11
        cin, cout, kernel = int(insn[1]), int(insn[2]), int(insn[3])
        return opcode * 2**27 + cin * 2**16 + cout * 2**5 + kernel
    elif op == 'cfgif':
        opcode = 12
        height, width = int(insn[1]), int(insn[2])
        return opcode * 2**28 + height * 2**16 + width * 2**5
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
    elif op == 'cvlif':
        opcode = 13
        addr = int(insn[1])
        return opcode * 2**27 + addr
    elif op == 'cvlw':
        opcode = 14
        addr = int(insn[1])
        return opcode * 2**27 + addr
    elif op == 'cvsof':
        opcode = 15
        addr = int(insn[1])
        return opcode * 2**27 + addr
    elif op == 'cvexec':
        opcode = 16
        return opcode * 2**27
    elif op == 'mplif':
        opcode = 21
        addr = int(insn[1])
        return opcode * 2**27 + addr
    elif op == 'mpsof':
        opcode = 22
        addr = int(insn[1])
        return opcode * 2**27 + addr
    elif op == 'mpexec':
        opcode = 23
        return opcode * 2**27
    elif op == 'eoc':
        opcode = 31
        return opcode * 2**27
    else:
        assert False, op


if __name__ == '__main__':
    program = []
    with open('program.genie', 'r') as f:
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
