// UART RX
// -------
//
// Using the clk, sample inputs and on a complete word, mark valid = 1 and
// buffer it for use.
//
// The clk is used as a source of baud, and with the divisor provides a rx
// only phase shifted baud clock. This allows for variance in clocks between
// sender and receiver only apply at the frame level, resulting in
// significantly less issues with drift or stretching.
//
//
// Note: divisor should be half that of the divisor required to match the
// target baud rate.

module uart_rx(clk, rst, rxi, data, valid);
	parameter integer bitwidth = 8;
	parameter integer divisor = 0;
	parameter integer startbits = 1;
	parameter integer stopbits = 1;
	parameter integer _framelen = bitwidth + startbits + stopbits;

	input wire clk, rst;
	input wire rxi;

	reg [_framelen - 1:0] sdata = {_framelen{1'b0}};
	output reg valid = 0;
	output wire [bitwidth - 1:0] data;
	assign data = sdata[_framelen - stopbits - 1: startbits];

	// buffer the rxi input at clk rate, which is faster than the divisor
	// rate.
	reg [1:0] rxi_buf = 2'b11;

	reg integer baud_counter = 0;
	reg integer cbit = 0;
	always @(posedge clk) begin
		if (rst == 1) begin
			rxi_buf <= 2'b11;
			baud_counter <= 0;
			sdata <= {_framelen{1'b0}};
			valid <= 0;
			cbit <= 0;
		end else begin
			// buffer rxi
			rxi_buf <= {rxi_buf[0], rxi};
			// reset valid state
			valid <= 0;

			// detect falling edge of start bit
			if (cbit == 0 && rxi_buf == 2'b10) begin
				// start the frame
				cbit <= cbit + 1;
				// the detection of the trigger takes 2 cycle, 1 for the
				// buffering, and the second as this detection is synchronous
				baud_counter <= 2;
			end else if (cbit != 0) begin
				baud_counter <= baud_counter + 1;

				if (baud_counter == divisor - 1) begin
					baud_counter <= 0;
					cbit <= cbit + 1;

					if (cbit[0] == 1) begin
						// When the counter is at ~ half way, sample the input as
						// sdata. Sampling the start bit is fine as it is dropped.
						`ifndef SYNTHESIS
							$display("sample bit %b here, cbit %d, b %d, %b|%h|%b",
								rxi_buf[0], cbit[31:1], baud_counter,
								rxi_buf[0], sdata[_framelen - 1:2], sdata[0]);
						`endif
						sdata <= {rxi_buf[0], sdata[_framelen - 1:1]};
					end else begin
						// When the counter has hit the divisor twice
						if (cbit == ((_framelen) * 2)) begin
							cbit <= 0;
							valid <= 1;
							`ifndef SYNTHESIS
								$display("valid here, %b|%h|%b",
									sdata[_framelen - 1],
									sdata[_framelen - 2:1],
									sdata[0]);
							`endif
						end
					end
				end
				if (cbit == 1 && rxi_buf[0] == 1) begin
					// Detect failed start bit, bit musts be low for at
					// least 1/2 expected width of bit. Otherwise
					// considered a stray pulse.
					`ifndef SYNTHESIS
						$display("stray pulse detected");
					`endif
					cbit <= 0;
				end
			end
		end
	end
endmodule
