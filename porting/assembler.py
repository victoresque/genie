
def assemble(insn):
    op = insn[0]
    bits = 0
    if op == 'cfgl':
        bits += 1 * 2**27
        layer, act, bias = insn[1], insn[2], insn[3]
        if layer == 'fc':
            layer = 1
        elif layer == 'conv':
            layer = 2
        if act == 'noact':
            act = 0
        elif act == 'relu':
            act = 1
        if bias == 'nobias':
            bias = 0
        else:
            bias = 1
        bits += layer * 2**16
        bits += act * 2**5
        bits += bias
    elif op == 'cfgfc':
        bits += 2 * 2**27
        cin, cout = insn[1], insn[2]
        bits += int(cin) * 2**16
        bits += int(cout) * 2**5
    elif op == 'lif':
        bits += 3 * 2**27
        addr = int(insn[1])
        bits += addr
    elif op == 'lw':
        bits += 4 * 2**27
        addr = int(insn[1])
        bits += addr
    elif op == 'sof':
        bits += 5 * 2**27
        addr = int(insn[1])
        bits += addr
    elif op == 'eoc':
        bits += 31 * 2**27
    return bits


if __name__ == '__main__':
    program = [
        ['cfgl', 'fc', 'relu', 'bias'],
        ['cfgfc', '784', '32'],
        ['lif', '26506'],
        ['lw', '0'],
        ['sof', '27290'],
        ['cfgl', 'fc', 'relu', 'bias'],
        ['cfgfc', '32', '32'],
        ['lif', '27290'],
        ['lw', '25120'],
        ['sof', '26506'],
        ['cfgl', 'fc', 'noact', 'bias'],
        ['cfgfc', '32', '10'],
        ['lif', '26506'],
        ['lw', '26176'],
        ['sof', '27290'],
        ['eoc']
    ]

    with open('../mem/insn.mem', 'w') as f:
        insn_mem_size = 8192
        f.write('@0\n')
        for insn in program:
            f.write('{:032b}\n'.format(assemble(insn)))
        f.write('@{:x}\n'.format(insn_mem_size-1))
