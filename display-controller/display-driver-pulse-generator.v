module display_driver_pulse_generator (clk, rst, go, complete, full_complete, select);
	parameter integer bitwidth = 8;

	// clock and reset
	input wire clk, rst;

	// bit select
	output wire [$clog2(bitwidth) - 1:0] select;
	assign select = pulse_bit[$clog2(bitwidth) - 1:0];

	// Pulse driver
	//
	// The pulsing are halved for each bit in the width. The drive
	// automatically halfs at the end of a cycle. this needs to be reset for
	// each row.
	//
	// Note: pulse_bit is MSB first, making pulse_bit == 0 >> bitwidth - 1
	//
	// 1111 1111 - 256 - bit 7
	//  111 1111 - 128 - bit 6
	//   11 1111 -  64 - bit 5
	//    1 1111 -  32 - bit 4
	//      1111 -  16 - bit 3
	//       111 -   8 - bit 2
	//        11 -   4 - bit 1
	//         1 -   2 - bit 0
	//
	input wire go;
	output reg complete = 0;
	output reg full_complete = 0;
	reg integer pulse_bit = 0;
	reg [bitwidth - 1:0] pulse_length = {bitwidth{1'b1}};
	reg [bitwidth - 1:0] pulse_counter = {bitwidth{1'b0}};
	always @(posedge clk) begin
		if (rst == 1) begin
			complete <= 0;
			full_complete <= 0;
			pulse_counter <= 0;
			pulse_bit <= 0;
			pulse_length <= {bitwidth{1'b1}};
		end else begin
			if (complete == 0 && go == 1) begin
				if (pulse_counter == pulse_length) begin
					complete <= 1;
					pulse_counter <= 0;
					if (pulse_bit == bitwidth - 1) begin
						pulse_bit <= 0;
						// reset to full
						pulse_length <= {bitwidth{1'b1}};
						full_complete <= 1;
					end else begin
						pulse_bit <= pulse_bit + 1;
						// half the length
						pulse_length <= {1'b0, pulse_length[bitwidth - 1:1]};
					end
				end else begin
					pulse_counter <= pulse_counter + 1;
				end
			end else begin
				complete <= 0;
				full_complete <= 0;
				pulse_counter <= 0;
			end
		end
	end
endmodule
