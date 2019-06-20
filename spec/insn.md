# Instructions

## Configuration
            [  31:27  |   26:16  |   15:5  |     4:0  ]
* Layer configuration
    cfgl    [      1  |    type  |    act  |    bias  ]


## Fully-connected layer
            [  31:27  |   26:16  |   15:5  |     4:0  ]
* FC configuration
    cfgfc   [      2  |     cin  |   cout  |          ]     // TODO: assembler, decode, change to cin[25:13], cout[12:0]

            [  31:27  |               26:0            ]
* Load input feature
    fclif   [      3  |               addr            ]    
* Load weight
    fclw    [      4  |               addr            ]
* Store output feature
    fcsof   [      5  |               addr            ]


## Convolutional Layer
            [  31:27  |   26:16  |   15:5  |  4:3  |     2:0  ]
* Conv2d configuration
    cfgcv   [     11  |     cin  |   cout  |  pad  |  kernel  ]


            [  31:27  |  26 |      25:13  |       12:0  ]
* Conv2d IF configuration
    cfgcvif [     12  |     |     height  |      width  ]

            [  31:27  |               26:0            ]
* Set input feature base address
    cvaif   [     13  |               addr            ]
* Set weight base address
    cvaw    [     14  |               addr            ]
* Set output feature base address
    cvaof   [     15  |               addr            ]
    
            [  31:27  |  26:9 |          8  |    7:0  ]
* PE select
    cvselpe [     16  |       |  broadcast  |   peid  ]

             [  31:27  |  26 |      25:13  |       12:0  ]
* Configure PE extents (sel=0: h,w; sel=1: i,o)
    cvcfgext [     17  | sel |  hext/iext  |  wext/oext  ]
* Configure PE origins (sel=0: h,w; sel=1: i,o)
    cvcfgori [     18  | sel |  hori/iori  |  wori/oori  ]

            [  31:27  |               26:0            ]
* Load input feature partition
    cvlifp  [     19  |                               ]
* Load weight partition
    cvlwp   [     20  |                               ]
* Store output feature partition
    cvsofp  [     21  |                               ]


## Max Pooling
            [  31:27  |               26:0            ]
* Set input feature base address
    mpaif   [     28  |               addr            ]
* Store output feature
    mpsof   [     29  |               addr            ]

## Status
* End of calculation
    eoc     [     31  |                               ]

