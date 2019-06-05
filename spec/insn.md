# High-level Functionality
* configurations
* load m weight from addr to buffer
* load m IF from addr to buffer
* store m OF to addr to buffer
* wait for input

# Instructions
## C-type
* Configuration
    C       [  31:27  |  26:16  |  15:5  |     4:0  ]
            [    2^5  |   2^11  |  2^11  |     2^5  ]
* Layer configuration
    cfgl    [      1  |   type  |   act  |    bias  ]
* FC configuration
    cfgfc   [      2  |    cin  |  cout  |          ]
## LS-type
* Load/store data
    L       [  31:27  |             26:0            ]
* Load input feature (fc)
    lif     [      3  |             addr            ]    
* Load weight (fc)
    lwfc    [      4  |             addr            ]
* Store output feature
    sof     [      5  |             addr            ]
## A-type
* Address initialization
    A       [  31:27  |             26:0            ]
* Initilize weight base address
    ainit   [     op  |             addr            ]
## ?-type
* Load weight (conv2d)
    lwcv    [     op  |                             ]
* End of calculation
    eoc     [     31  |                             ]

# Examples
* Assume T1, T2, T3 = 32, 32, 32

* DNN example
```
    wfi
// layer 1
    cfgl, fc, relu, bias
    cfgfc, 784, 32
    lif, 26506
    lwfc, 0
    sof, 27290
// layer 2
    cfgl, fc, relu, bias
    cfgfc, 32, 32
    lif, 27290
    lwfc, 25120
    sof, 26506
// layer 3
    cfgl, fc, noact, bias
    cfgfc, 32, 10
    lif, 26506
    lwfc, 26176
    sof, 27290
```

* CNN example
