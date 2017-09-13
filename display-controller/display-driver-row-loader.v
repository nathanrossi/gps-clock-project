module display_driver_row_loader (clk, rst, load, complete, oclk, column, pipe);
	parameter integer pipe_length = 1;
	parameter integer columns = 32; // number of bits per line
	parameter integer bitwidth = 8;

	// clock and reset
	input wire clk, rst;

	// Row serial loader
	//
	// Controls the load of bits for a row load. This involves the clocking of
	// oclk and waiting on the pipe to push the pixel bits.
	//
	// Due to how oclk needs to be synchronous this forces this process to
	// work at half the rate of the input clock.
	//
	// This does not assert latch, but the 'complete' signal can be used for
	// that purpose.
	//
	// Timing:
	//
	// load      | L | L | L | L | L ....                      L | X | ? |
	// oclk      | o | o | o | o ^ O | o | O | o | O |...| o | O | o | o |
	// pre       | 0 | 1 | 2 | 3     | 4     | 5     |...| 33    | 0     |
	// col valid | 0 | 1 | 2 | 3     | 4     | 5     |...|???????| 0     |
	// pipe go   |   ^ P ^ P |   ^ P |   | P |   | P |...|   | P |   |   |
	// pipe [0]  |???|???|???|<0    >|<1    >|<2    >|...|<31   >|???????|
	// pipe [1]  |???|???|<0>|<1    >|<2    >|<3    >|...|???????????????|
	// pipe in   |???|<0>|<1>|<2>|<3    >|<3    >|<4  ...|???????????????|
	// complete  |   |   |   |   |   |   |   |   |   |...|   |   | X |   |
	//
	// Above example is with a pipe of 2 in length, this requires 2 prepare
	// steps before the actual data is valid on the output.
	//
	// Note: the pipe go signal is causes the subsequent cycle to move the
	// pipe along.
	//
	// * column/prepared is incremented on the oclk = 1 cycle or when prepared
	//   is less than the length

	input wire load;
	output reg complete = 0;
	output reg oclk = 0;
	output reg pipe = 0;

	reg integer prepared = 0;
	output wire [$clog2(columns) - 1:0] column;
	assign column = prepared[$clog2(columns) - 1:0];

	always @(posedge clk) begin
		if (rst == 1) begin
			prepared <= 0;
			complete <= 0;
			pipe <= 0;
		end else begin
			if (complete == 0 && load == 1) begin
				if (oclk == 0 || (prepared < pipe_length)) begin
					// if prepared complete, then raise pulse
					if (prepared > pipe_length) begin
						// consume and oclk
						oclk <= 1;
						pipe <= 1;
					end else if (prepared == pipe_length) begin
						// the pipe is prepared, setup the next column but
						// don't consume it yet
						pipe <= 0;
					end else begin
						pipe <= 1;
					end
				end else if (oclk == 1) begin
					// complete a oclk pulse.
					oclk <= 0;
					pipe <= 0;
				end

				// increment prepared before oclking, be when oclking only
				// increment on oclk = 1 phase
				if ((oclk == 0 && prepared <= pipe_length) || (oclk == 1 && prepared > pipe_length)) begin
					// push the increment values for the next pipe
					if (prepared == pipe_length + columns) begin
						complete <= 1;
						// reset prepared to 0 so that for the cycle after
						// complete assert the output is valid for an
						// immediate restart of loading.
						prepared <= 0;
					end else begin
						prepared <= prepared + 1;
					end
				end
			end else begin
				// deassert state, and wait for load = 1.
				prepared <= 0;
				complete <= 0;
				pipe <= 0;
				oclk <= 0;
			end
		end
	end
endmodule
