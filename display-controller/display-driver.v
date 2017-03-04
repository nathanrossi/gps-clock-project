//
// Display Driver control machine
// ------------------------------
//
// This module is to be used as a single instance controlling a single
// display. Multple display segments can be achieved with multiple frame
// buffers and PWM comparitors.
//
// A = multi-bit row address
// LAT = active low, pulse to load/latch data
// OE = active low, hold high during load, drop to low otherwise
// CLK = rising edge
//

// Clocking information:
// ---------------------
// This module has the following timing characteristics.
// Each full refresh consumes ((((columns * 2) + 2 + (row_porch)) * rows) * cycles) cycles
//
// For a 8 row, 32 line display with 256 cycles (row_porch == 1). The frame
// will take 71680 cycles. With a 12 MHz clock a refresh rate of ~167 Hz can
// be achieved.
//

module display_driver(clk, rst, row, column, cycle, oe, lat, oclk);
	parameter rows = 8; // number of addressable rows
	parameter columns = 32; // number of bits per line
	parameter cycles = 256;
	parameter row_post = 8; // the number of cycles to hold OE low before next row

	input clk, rst;
	wire clk, rst;

	output oe, lat, oclk;
	reg oe = 1, lat = 1;
	reg oclk = 0;

	// row counter
	output [$clog2(rows)-1:0] row;
	reg [$clog2(rows)-1:0] row = 0;

	// column counter
	output [$clog2(columns)-1:0] column;
	reg [$clog2(columns)-1:0] column = 0;

	// cycle counter
	output [$clog2(cycles)-1:0] cycle;
	reg [$clog2(cycles)-1:0] cycle = 0;

	// row post dwell
	reg [$clog2(row_post)-1:0] r_post = 0;

	integer state = 0;
	always @(posedge clk) begin
		if (rst == 1) begin
			cycle <= 0;
			row <= 0;
			column <= 0;
			r_post <= 0;
			oe <= 1;
			lat <= 1;
			oclk = 0;
			state <= 0;
		end else begin
			if (state == 0) begin // raise oclk
				lat <= 1;
				oe <= 1;
				oclk = 0;
				state <= 1;
			end else if (state == 1) begin // clk low, load next
				// if this is the last column of the row, move latch phase
				if (column >= columns - 1) begin
					column <= 0;
					state <= 2;
				end else begin
					column <= column + 1;
					state <= 0;
				end
				lat <= 1;
				oe <= 1;
				oclk = 1;
			end else if (state == 2) begin // latch the row
				// keeping the row at the same address as the row
				// being latched.
				state <= 3;
				lat <= 0;
				oe <= 1;
				oclk = 0;
			end else if (state == 3) begin // output hold the row,
				// hold the output enable low, on the latched/loaded
				// row.
				if (r_post >= row_post -1) begin
					state <= 4;
					r_post <= 0;
				end else begin
					r_post <= r_post + 1;
				end
				lat <= 1;
				oe <= 0;
				oclk = 0;
			end else if (state == 4) begin // move to next row
				if (row >= rows - 1) begin
					// Next cycle, completed the set of rows
					row <= 0;
					if (cycle >= cycles - 1) begin
						// Each complete cycles is equivalent to a single vertical
						// refresh of the display. The display refresh rate is
						// equivalent to 1/<number of cycles completed>.
						//
						// Additionally each full cycle revolution is when frame
						// buffer switching should occur. This avoids incorrect colour
						// reprensentation as well as tearing.
						cycle <= 0;
					end else begin
						cycle <= cycle + 1;
					end
				end else begin
					row <= row + 1;
				end
				state <= 0;
				lat <= 1;
				oe <= 1;
				oclk = 0;
			end
		end
	end
endmodule

