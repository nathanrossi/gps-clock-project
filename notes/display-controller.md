
Diagram
=======

Display Framebuffer to Output
=============================

```

    ___________________
   |                   |
   | Frame Buffer Unit |<----- ROW
   |  (x2)             |<----- COL
   |___________________|                             _____________
                    |||                            _|____________ |
                    |||                          _|_____________ ||
                    \\\------------- R[7:0] --->|               |||-----R ----->
                     \\------------- G[7:0] --->| PWM converter ||----- G ----->
                      \------------- B[7:0] --->|_______________|------ B ----->
                                                   ^
                                                   |
                                                   \---- CYCLE

```

Display driver works in phase with loading from the frame buffer. The fetch
occurs one cycle before the latch.

1. Fetch row/col RGB data
2. Apply PWM cycle pixel state, (should it be 0/1 during this cycle).
3. Latch the state into the display

Pipeline:
---------

```
   |<f r0c00>|<f r0c01>|............|<f r0c31>|<f r1c00>|
             |<l r0c00>|<l r0c01>|............|<l r0c31>|
```



