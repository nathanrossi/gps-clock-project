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
// This core is very simple and only supports 8N1.

module uart_rx(clk, rst, rxi, data, valid);
	parameter integer bitwidth = 8;
	parameter integer divisor = 0; // the baud rate divisor of clk

	input wire clk, rst;
	input wire rxi;

	output reg [bitwidth - 1:0] data = {bitwidth{1'b0}};
	output reg valid = 0;

	// buffer the rxi input at clk rate, which is faster than the divisor
	// rate.
	reg [1:0] rxi_buf = 2'b11;
	always @(posedge clk) rxi_buf <= {rxi_buf[0], rxi};

	reg integer baud_counter = 0;
	reg integer cbit = 0;
	always @(posedge clk) begin
		if (rst == 1) begin
			rxi_buf <= 2'b11;
			baud_counter <= 0;
			data <= {bitwidth{1'b0}};
			valid <= 0;
			cbit <= 0;
		end else begin
			// detect falling edge of start bit
			if (cbit == 0 && rxi_buf == 2'b10) begin
				// start the frame
				cbit <= cbit + 1;
				baud_counter <= 0;
				valid <= 0;
			end else if (cbit != 0) begin
				baud_counter <= baud_counter + 1;
				if (cbit == 1 && rxi_buf[0] == 1) begin
					// Detect failed start bit, bit musts be low for at
					// least 1/2 expected width of bit. Otherwise
					// considered a stray pulse.
					cbit <= 0;
				end else if (baud_counter == divisor / 2) begin
					// When the counter is at ~ half way, sample the input as
					// data. Sampling the start bit is fine as it is dropped.
					data <= {rxi_buf[0], data[7:1]};
					cbit <= cbit + 1;
					// set valid here, this gives time to process before the
					// next input word
					if (cbit == 9) begin
						valid <= 1;
					end
				end else if (baud_counter >= divisor) begin
					// When the counter has hit the divisor
					if (cbit == 10) begin
						cbit <= 0;
					end
					baud_counter <= 0;
				end
			end
		end
	end
endmodule
