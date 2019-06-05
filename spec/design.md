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
id    Type   Act        dim     addr   Bias     Baddr
-----------------------------------------------------
1   Linear  ReLU    784, 32        0     32     25088
2   Linear  ReLU     32, 32    25120     32     26144
3   Linear           32, 10    26176     10     26496  
4       F0                     26506
5       F1                     27290

* CNN example

id     Type   Act            dim         addr      ofsize
-----------------------------------------------------------
0     Input               28, 28                      784
1    Conv2d  ReLU    16, 1, 3, 3            0       10816
2      MP2d                                          2704
3    Conv2d  ReLU   32, 16, 3, 3          160        3872
4      MP2d                                           800
5    Conv2d  ReLU   16, 32, 3, 3         4800         576
6    Linear              144, 10         9424          10
7        F0                             10874
8        F1                             21690

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

