import numpy as np


def select_strategy(H, W, I, O, K, Hp, Wp, IFRAM, WRAM, OFRAM, SMAX, WSMAX, RDLAT, WRLAT):
    """
        H:     input feature height
        W:     input feature width
        I:     input channel
        O:     output channel
        K:     kernel size
        Hp:    PE height
        Wp:    PE width
        IFRAM: input feature SRAM
        WRAM:  weight SRAM
        OFRAM: output feature/partial sum SRAM
        SMAX:  
        WSMAX: 
        RDLAT: external memory read latency
        WRLAT: external memory write latency
    """

    constraint_met = [0, 0, 0]
    memory_access = [np.inf, np.inf, np.inf]

    # Strategy 0: channel partition
    S = min(IFRAM // (Hp*Wp), WRAM // (O*K*K), SMAX)
    print('CP: S = {}'.format(S))
    if S != 0:
        ifram = S*Hp*Wp
        wram = O*S*K*K
        ofram = O*Hp*Wp
        if ofram <= OFRAM:
            constraint_met[0] = 1
            memory_access[0] = I*H*W*RDLAT + O*I*K*K*RDLAT \
                + O*H*W*(RDLAT+WRLAT)*np.ceil(I/S)
        else:
            print('CP not met: OFRAM {} > {}.'.format(ofram, OFRAM))
    else:
        print('CP not met: S = 0.')

    # Strategy 1: feature partition, weight reload
    WS = min(WRAM // (I*K*K), OFRAM // (Hp*Wp), WSMAX)
    print('FP: WS = {}'.format(WS))
    if WS != 0:
        ifram = I*Hp*Wp
        wram = WS*I*K*K
        ofram = WS*Hp*Wp
        if ifram <= IFRAM:
            constraint_met[1] = 1
            memory_access[1] = I*H*W*RDLAT + O*H*W*WRLAT \
                + O*I*K*K*np.ceil(H/Hp)*np.ceil(W/Wp)*RDLAT
        else:
            print('FPWR not met: IFRAM {} > {}.'.format(ifram, IFRAM))
    else:
        print('FPWR not met: WS = 0.')

    # Strategy 2: feature partition, feature reload
    WS = min(WRAM // (I*K*K), OFRAM // (Hp*Wp), WSMAX)
    if WS != 0:
        ifram = I*Hp*Wp
        wram = WS*I*K*K
        ofram = WS*Hp*Wp
        if ifram <= IFRAM:
            constraint_met[1] = 1
            memory_access[2] = I*H*W*np.ceil(O/S)*RDLAT \
                + O*H*W*WRLAT + O*I*K*K*RDLAT
        else:
            print('FPFR not met: IFRAM {} > {}.'.format(ifram, IFRAM))
    else:
        print('FPFR not met: WS = 0.')

    print(memory_access)
    print(np.argmin(memory_access))

    strategy = np.argmin(memory_access)


if __name__ == '__main__':
    select_strategy(64, 64, 8, 16, 3, 12, 12,
                    12000, 12000, 12000, 16, 16, 1, 1)
