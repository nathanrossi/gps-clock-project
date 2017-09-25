// UART TX
// -------
//
// Using the clk, generate outputs for data when valid is asserted. The input
// is first buffered during the valid.
//
// The clk is used as a source of baud, and with the divisor provides a tx
// only phase shifted baud clock. This allows for variance in clocks between
// sender and receiver only apply at the frame level, resulting in
// significantly less issues with drift or stretching.
//
// This core is very simple and only supports 8N1.

module uart_tx(clk, rst, txo, data, valid);
	parameter integer bitwidth = 8;
	parameter integer divisor = 32;
	parameter integer startbits = 1;
	parameter integer stopbits = 1;
	parameter integer _framelen = bitwidth + startbits + stopbits;

	input wire clk, rst;
	output reg txo = 1;

	input wire [bitwidth - 1:0] data;
	input wire valid;

	reg [_framelen - 2:0] sdata = {_framelen{1'b0}};

	reg [$clog2(divisor) - 1:0] baud_counter = 0;
	reg [$clog2(_framelen):0] cbit = 0;
	always @(posedge clk) begin
		if (rst == 1) begin
			baud_counter <= 0;
			cbit <= 0;
			sdata <= {_framelen{1'b0}};
			txo <= 1;
		end else begin
			if (cbit != 0) begin
				baud_counter <= baud_counter + 1;
				if (baud_counter == divisor - 1) begin
					// When the counter has hit the divisor
					// shift sdata
					sdata <= {1'b1, sdata[_framelen - 2:1]};
					// next bit to txo
					txo <= sdata[0];
					// reset count
					baud_counter <= 0;
					cbit <= cbit + 1;
					if (cbit == _framelen) begin
						cbit <= 0;
					end
				end
			end else begin
				// idle txo high
				txo <= 1;
				// if not pushing a bit, check for valid and start pushing
				// a bit
				if (valid == 1) begin
					// mark start, and buffer data
					baud_counter <= 0;
					cbit <= 1;
					sdata <= {{stopbits{1'b1}}, data, {startbits - 1{1'b0}}};
					txo <= 0; // start bit
				end
			end
		end
	end
endmodule
