# Instructions

## Configuration
            [  31:27  |   26:16  |   15:5  |     4:0  ]
* Layer configuration
    cfgl    [      1  |    type  |    act  |    bias  ]
* FC configuration
    cfgfc   [      2  |     cin  |   cout  |          ]
* Conv2d configuration
    cfgcv   [     11  |     cin  |   cout  |  kernel  ]
* Conv2d IF configuration
    cfgif   [     12  |  height  |  width  |          ]

## Fully-connected layer
            [  31:27  |               26:0           ]
* Load input feature
    fclif   [      3  |               addr           ]    
* Load weight
    fclw    [      4  |               addr           ]
* Store output feature
    fcsof   [      5  |               addr           ]

## Convolutional Layer
            [  31:27  |               26:0           ]
* Load input feature
    cvlif   [     13  |               addr           ]
* Load weight
    cvlw    [     14  |               addr           ]
* Store output feature
    cvsof   [     15  |               addr           ]
* Execution
    cvexec  [     16  |                              ]

## Max Pooling
            [  31:27  |               26:0           ]
* Load input feature
    mplif   [     21  |               addr           ]
* Store output feature
    mpsof   [     22  |               addr           ]
* Execution
    mpexec  [     23  |                              ]

## Status
* End of calculation
    eoc     [     31  |                              ]


# Examples
* DNN example
```
// layer 1
    cfgl, fc, relu, bias
    cfgfc, 784, 32
    fclif, 26506
    fclw, 0
    fcsof, 27290
// layer 2
    cfgl, fc, relu, bias
    cfgfc, 32, 32
    fclif, 27290
    fclw, 25120
    fcsof, 26506
// layer 3
    cfgl, fc, noact, bias
    cfgfc, 32, 10
    fclif, 26506
    fclw, 26176
    fcsof, 27290
    eoc
```

* CNN example
```
// conv 1
    cfgl, conv, relu, bias
    cfgcv, 1, 16, 3
    cfgif, 28, 28
    cvlif, 10874
    cvlw, 0
    cvsof, 21690
    cvexec
// max pooling 1
    cfgl, mp
    cfgif, 26, 26
    mplif, 21690
    mpsof, 10874
    mpexec
// conv 2
    cfgl, conv, relu, bias
    cfgcv, 16, 32, 3
    cfgif, 13, 13
    cvlif, 10874
    cvlw, 160
    cvsof, 21690
    cvexec
// max pooling 2
    cfgl, mp
    cfgif, 11, 11
    mplif, 21690
    mpsof, 10874
    mpexec
// conv 3
    cfgl, conv, relu, bias
    cfgcv, 32, 64, 3
    cfgif, 5, 5
    cvlif, 10874
    cvlw, 4800
    cvsof, 21690
    cvexec
// conv 3
    cfgl, conv, relu, bias
    cfgcv, 64, 10, 3
    cfgif, 3, 3
    cvlif, 21690
    cvlw, 9424
    cvsof, 10874
    cvexec
    eoc
```

