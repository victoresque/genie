# Model descriptor
* Layer type
  * Linear
  * ReLU
  * MaxPool2d
  * Conv2d
    * kernel size (3x3, *1x1 ~ 5x5*)
    * *stride (1 ~ 2)*
    * *padding (0 ~ 2)*
  * Flatten
* Layer dimension
* Weight address base
* Output feature address base

* DNN example
```
id    Type   Act        dim     addr   Bias     Baddr
-----------------------------------------------------
1   Linear  ReLU    784, 32        0     32     25088
2   Linear  ReLU     32, 32    25120     32     26144
3   Linear           32, 10    26176     10     26496  
4       F0                     26506
5       F1                     27290
```

* CNN example
```
id     Type   Act            dim     addr   Bias     Baddr
----------------------------------------------------------
1    Conv2d  ReLU    16, 1, 3, 3        0     16       144
2      MP2d
3    Conv2d  ReLU   32, 16, 3, 3      160     32      4768
4      MP2d
5    Conv2d  ReLU   64, 32, 3, 3     4800     64     23232
6    Conv2d         10, 64, 3, 3    23296     10     29056
7        F0                         29066
8        F1
```

* CNN w/ flatten example
```
```

# Dimension and Hardware Constraints
* Linear
  - Weight: I x O
    * Active buffer: T1 x T2
  - Input feature: I
    * Active buffer: I
  - Output feature: O
    * Active buffer: O
* Conv2d
  - Weight: O x I x K x K
    * Active buffer: O x K x K
  - Input feature: I x H x W
    * Active buffer: T3 x T3
  - Output feature: O x H' x W'
    * H', W' = ((H+2xpad-K)//strd+1), ((W+2xpad-K)//strd+1)
    * Active buffer: T3 x T3

