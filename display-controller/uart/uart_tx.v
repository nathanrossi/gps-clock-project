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
	parameter integer divisor = 0; // the baud rate divisor of clk

	input wire clk, rst;
	output reg txo = 1;

	input wire [bitwidth - 1:0] data;
	input wire valid;

	reg [bitwidth - 1:0] sdata = {bitwidth{1'b0}};

	reg integer baud_counter = 0;
	reg integer cbit = 0;
	always @(posedge clk) begin
		if (rst == 1) begin
			baud_counter <= 0;
			cbit <= 0;
			sdata <= {bitwidth{1'b0}};
			txo <= 1;
		end else begin
			if (cbit != 0) begin
				baud_counter <= baud_counter + 1;
				if (baud_counter >= divisor - 1) begin
					// When the counter has hit the divisor
					baud_counter <= 0;
					cbit <= cbit + 1;
					if (cbit == 9) begin
						// stop bit
						txo <= 1;
					end else if (cbit == 10) begin
						cbit <= 0;
					end else begin
						// data bits
						txo <= sdata[0];
						// shift for next
						sdata <= {1'b0, sdata[7:1]};
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
					sdata <= data;
					txo <= 0; // start bit
				end
			end
		end
	end
endmodule
