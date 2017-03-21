
Diagram
=======

Display Framebuffer to Output
=============================

Data Path:
```

    ___________________
   |                   |
   | Frame Buffer Unit |<----- ROW
   | (1 per segment)   |<----- COL
   |___________________|
     ^              |||  Color Correction       PWM
     \- CLK         |||    ____                _____
                    \\\---|    |-- R[7:0] --->|     |-- R -->
                     \\---|    |-- G[7:0] --->|     |-- G -->
                      \---|____|-- B[7:0] --->|_____|-- B -->
                              ^                  ^^
                              \- CLK             |\- CLK
                                                 \---- CYCLE

```

Display driver works in phase with loading from the frame buffer. The fetch
occurs one cycle before the latch. This allows for the pipelining of data,
however this is only updated every second clk cycle due to oclk being driven by
the control path.

1. Fetch row/col RGB data
2. Apply color/gamma correction (per channel)
3. Apply PWM cycle pixel state
4. Latch the state into the display

Display Controller SPI Interface
================================

Max SPI Clock = 6 MHz (currently)

The slave SPI interface on the display controller also includes a rising edge
triggered interrupt signal line to indicate that the device is ready to receive
an updated frame.

In order to write a frame to the device it is written as a single 'command'
during the CS active state. The first word (8-bit words) must be the value
`0xf0`. Then each pixel must be written with 3 words, the pixels alternate
between segments. This means that pixel 0x0 of segment 0, then pixel 0x0 of
segment 1, then pixel 1x0 of segment 0, ... so forth until all pixels are
written after which all data will be dropped until CS is deactivated.
Additionally the frame will not swap until CS is deactivated. Partially updating
the screen is also acceptable, this will however result in potentially incorrect
display output where the frame before the last updated frame will be in the
frame buffer and partly updated.

The SPI interface buffers pixels for each segment, then writes the pixels into
the frame buffer on the un-swapped memory addresses. This allows for clean frame
updates that do not tear or have odd color artefacts.

