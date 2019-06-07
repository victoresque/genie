# Instructions

## Configuration
            [  31:27  |   26:16  |   15:5  |     4:0  ]
* Layer configuration
    cfgl    [      1  |    type  |    act  |    bias  ]


## Fully-connected layer
            [  31:27  |   26:16  |   15:5  |     4:0  ]
* FC configuration
    cfgfc   [      2  |     cin  |   cout  |          ]

            [  31:27  |               26:0            ]
* Load input feature
    fclif   [      3  |               addr            ]    
* Load weight
    fclw    [      4  |               addr            ]
* Store output feature
    fcsof   [      5  |               addr            ]


## Convolutional Layer
            [  31:27  |   26:16  |   15:5  |     4:0  ]
* Conv2d configuration
    cfgcv   [     11  |     cin  |   cout  |  kernel  ]
* Conv2d IF configuration
    cfgcvif [     12  |  height  |  width  |          ]

            [  31:27  |               26:0            ]
* Set input feature base address
    cvaif   [     13  |               addr            ]
* Set weight base address
    cvaw    [     14  |               addr            ]
* Set output feature base address
    cvaof   [     15  |               addr            ]
* PE select
    cvselpe [     16  |               peid            ]
    
            [  31:27  |   26:16  |    15:8  |    7:0  ]
* PE output feature range
    cvcfgpe [     17  |    oext  |    hext  |   wext  ]
* Load input feature partition
    cvlifp  [     18  |          |    hori  |   wori  ]
* Load weight partition
    cvlwp   [     19  |    oori  |          |         ]
* Store output feature partition
    cvsofp  [     20  |    oori  |    hori  |   wori  ]


## Max Pooling
            [  31:27  |               26:0            ]
* Load input feature
    mplif   [     28  |               addr            ]
* Store output feature
    mpsof   [     29  |               addr            ]

## Status
* End of calculation
    eoc     [     31  |                               ]


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
    cfgcvif, 28, 28
    cvaif, 10874
    cvaw, 0
    cvaof, 21690
    cvselpe, 0
    cvcfgpe, 12, 12, 12
    cvlifp, 0, 0, 0
    cvlwp, 0 
    cfsof, 0, 0, 0
    cvcfgpe, 12, 12, 12

```

