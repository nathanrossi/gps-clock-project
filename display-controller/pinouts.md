
Pinout (icestick)
=================

Headers:
--------
```

         J1                    J3
         [] 3V3            3V3 []
         [] GND            GND []
  rgb[0] [] 112             62 [] a[0]
  rgb[1] [] 113             61 [] a[1]
  rgb[2] [] 114             60 [] a[2]
  rgb[3] [] 115             56 [] oe
  rgb[4] [] 116             48 [] lat
  rgb[5] [] 117             47 [] oclk
    sclk [] 118             45 [] mosi
      ss [] 119             44 [] miso

```

Fixed Function:
---------------

```
ICE_CLK - 21 - 12MHz clock signal
```

Pinout (up5k)
=============

```
HEADER B

3 : IOT_37A --> 23
5 : IOT_36B --> 25
7 : IOT_39A --> 26 <> PMOD8
9 : IOT_38B --> 27 <> PMOD7
11: IOT_43A --> 32 <> PMOD9
13: IOT_42B --> 31 <> PMOD10
15: IOT_345A_G1 [xxx] --> 37
17: IOT_44B --> 34
19: IOT_49A --> 43

8 : IOT_48B --> 36
10: IOT_51A --> 42
12: IOT_50B --> 38
14: IOT_41A --> 28
16: ICE_CLK

HEADER C

3 : IOB_8A --> 4
5 : IOB_9B --> 3
7 : IOB_4A --> 48
9 : IOB_5B --> 45
11: IOB_2A --> 47
13: IOB_3B_G6 --> 44
15: IOB_0A --> 46
17: IOB_6A --> 2

2 : IOB_22A --> 12
4 : IOB_23B --> 21
6 : IOB_24A --> 13
8 : IOB_25B_G3 --> 20
10: IOB_29B --> 19
12: IOB_31B --> 18
14: IOB_20A --> 11
16: IOB_18A --> 10
18: IOB_16A --> 9
20: IOB_13B --> 6
```

