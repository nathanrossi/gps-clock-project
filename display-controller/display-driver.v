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

module display_driver(clk, rst, row, column, cycle, safe_flip, oe, lat, oclk);
	parameter rows = 8; // number of addressable rows
	parameter columns = 32; // number of bits per line
	parameter cycles = 256;
	parameter row_post = 8; // the number of cycles to hold OE low before next row

	input clk, rst;
	wire clk, rst;

	output safe_flip, oe, lat, oclk;
	reg oe = 1, lat = 1;
	reg oclk = 0;
	reg safe_flip = 0;

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

	// Expected function use.
	//
	//
	// -> col -> bram -> pwm -> out
	//     1      1       1
	//
	// load_addr
	// <> (row and col addresses valid)
	// load_value
	// <> (ram output valid)
	// load_encode
	// <> (PWM encoded) (next col address valid)
	//
	// column pulse high
	// <> (outputs valid) (ram output valid)
	// <> (clk -> 1)
	// column pulse low (same as load_encode)
	// <> (PWM encoded) (next col address valid)
	// <> (clk -> 0)
	// column pulse high
	// <> (outputs valid) (ram output valid)
	// <> (clk -> 1)
	// ....
	// column pulse low
	// <> (PWM encoded) (next col is invalid, move to latch/row)
	// <> (clk -> 0)
	//
	// row latch pulse active
	// <> (/lat -> 0)
	// <> (clk -> 0)
	// <> (row address still valid)
	// row latch pulse inactive
	// <> (/lat -> 1)
	// <> (row address still valid)
	//
	// row oe hold
	// <> (/oe -> 0)
	// row hold (waiting for post charge to finish)
	// ...
	// 0 A, 1 A, 2 A, 3 A, 4 A, 5 A, 6 A, 7 A
	// ...
	// row oe hold (post = top)
	// <> post <= 0
	// row oe release
	// <> (/oe -> 1)
	// <> -> row complete
	//
	// row complete
	// <> row ++
	// <> cycle ++
	// <> frame ++
	// <> move to load_addr if cycle ! wrap else move to frame hold
	// <> flip safe here
	//

	integer state = 0;
	parameter
		_load_addr = 0,
		_load_value = 1,
		_load_encode = 2,
		_col_ph = 3,
		_col_pl = 4,
		_row_lath = 5,
		_row_latl = 6,
		_row_oe = 7,
		_row_complete = 8;

	always @(posedge clk) begin
		if (rst == 1) begin
			lat <= 1; oe <= 1; oclk <= 0; safe_flip <= 0;
			cycle <= 0;
			row <= 0;
			column <= 0;
			r_post <= 0;
			state <= _load_addr;
		end else begin
			case (state)
				_load_addr: begin
					// during this state wait for the address signals to
					// propagate to the output of the regsters.
					lat <= 1; oe <= 1; oclk <= 0; safe_flip <= 0;
					state <= _load_value;
				end
				_load_value: begin
					// during this state wait for the bram to fetch and buffer
					// the addressed value on its output.
					lat <= 1; oe <= 1; oclk <= 0; safe_flip <= 0;
					state <= _load_encode;
				end
				_load_encode: begin
					// during this state wait for the ecoded value to hit the
					// output, update the column count.
					lat <= 1; oe <= 1; oclk <= 0; safe_flip <= 0;
					state <= _col_ph;
					// update the column addr
					if (column >= columns - 1) begin
						column <= 0;
					end else begin
						column <= column + 1;
					end
				end
				_col_ph: begin
					lat <= 1; oe <= 1; oclk <= 1; safe_flip <= 0;
					state <= _col_pl;
				end
				_col_pl: begin
					// this state is a duplicate of the _load_encode state,
					// however when the column is 0, move to the _row_lath
					lat <= 1; oe <= 1; oclk <= 0; safe_flip <= 0;
					// update the column addr
					if (column == 0) begin
						state <= _row_lath;
					end else if (column >= columns - 1) begin
						column <= 0;
						state <= _col_ph;
					end else begin
						column <= column + 1;
						state <= _col_ph;
					end
				end
				_row_lath: begin
					// this state is used to enable the latch signal
					lat <= 0; oe <= 1; oclk <= 0; safe_flip <= 0;
					state <= _row_latl;
				end
				_row_latl: begin
					// this state is used to disable the latch signal, for
					// a clean transition to the /oe hold phase
					lat <= 1; oe <= 1; oclk <= 0; safe_flip <= 0;
					state <= _row_oe;
				end
				_row_oe: begin
					// this state holds the /oe signal active for row_post
					// cycles, then moves to the _row_complete state.
					lat <= 1; oe <= 0; oclk <= 0; safe_flip <= 0;
					if (r_post >= row_post - 1) begin
						state <= _row_complete;
						r_post <= 0;
					end else begin
						r_post <= r_post + 1;
					end
				end
				_row_complete: begin
					// this state increments addresses and allows for a cycle
					// to flip the frame buffer safely.
					lat <= 1; oe <= 1; oclk <= 0;
					state <= _load_addr;
					if (row >= rows - 1) begin
						// Next cycle, completed the set of rows
						row <= 0;
						if (cycle >= cycles - 1) begin
							// Each complete of cycles is equivalent to a full
							// vertical refresh of the display.
							//
							// Additionally each full cycle revolution is when frame
							// buffer switching should occur. This avoids incorrect colour
							// reprensentation as well as tearing. This window
							// for flipping is a single cycle due to the
							// pipelining of the addr counters -> bram ->
							// encoder being synchronous.
							cycle <= 0;
							safe_flip <= 1;
						end else begin
							cycle <= cycle + 1;
							safe_flip <= 0;
						end
					end else begin
						row <= row + 1;
						safe_flip <= 0;
					end
				end
				default: state <= _load_addr;
			endcase
		end
	end
endmodule

