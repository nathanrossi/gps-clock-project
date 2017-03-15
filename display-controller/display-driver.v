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

module display_driver_mod2(clk, rst, row, column, cycle, safe_flip, oe, lat, oclk);
	parameter rows = 8; // number of addressable rows
	parameter columns = 32; // number of bits per line
	parameter bitdepth = 8;
	parameter _depthcount = (2 ** bitdepth);

	input clk, rst;
	wire clk, rst;

	output safe_flip, oe, lat, oclk;
	reg oe = 1, lat = 0;
	reg oclk = 0;
	reg safe_flip = 0;

	// row counter
	output [$clog2(rows)-1:0] row;
	reg [$clog2(rows)-1:0] row = 0;

	// column counter
	output [$clog2(columns)-1:0] column;
	reg [$clog2(columns)-1:0] column = 0;

	// cycle counter
	output [bitdepth-1:0] cycle;
	reg [bitdepth-1:0] cycle = 0;

	// Expected function use.
	//
	// -> col -> bram -> pwm -> out
	//     1      1       1
	// Takes 3 cycles/states for a addr change to reach the output
	// Takes 2 cycles/states for a cycle change to reach the output
	//
	// load_addr
	// <> (row and col addresses valid)
	// load_value
	// <> (ram output valid)
	// load_encode
	// <> (PWM encoded) (next col address valid)
	//
	// {
	//     col pl ph
	//     <> (outputs valid) (ram output valid)
	//     <> (clk -> 1)
	//     col pl pl
	//     <> (PWM encoded) (next col address valid)
	//     <> (clk -> 0)
	//     ... 32 times
	//     <> col == 0
	// }
	// col pl plath
	// <> (/lat -> 1)
	// <> (col valid)
	// <> (cycle valid)
	// col pl platl
	// <> (/lat -> 0)
	//
	// {
	//     {
	//         col l ph
	//         <> (outputs valid) (ram output valid)
	//         <> (clk -> 1)
	//         <> (/oe -> 0)
	//         col l pl
	//         <> (PWM encoded) (next col address valid)
	//         <> (clk -> 0)
	//         <> (/oe -> 0)
	//         ... 32 times
	//         <> col == 0
	//     }
	//     col l plath
	//     <> (/oe -> 1)
	//     <> (/lat -> 1)
	//     <> (col valid)
	//     <> (cycle valid)
	//     col l platl
	//     <> (/lat -> 0) (only latch with cycle != 0)
	//     ... repeat cycle times
	// }
	//
	// row complete
	// <> cycle = 0
	// <> row ++ (or wrap to next frame)
	// <> flip safe here
	//
	// MOD2 - > cycle on the row, avoid row switching for pwm'ing of bits
	//
	integer latch_delay = 0;

	integer state = 0;
	parameter
		_load_addr = 0,
		_load_value = 1,
		_load_encode = 2,
		_colpl_ph = 3, // preload
		_colpl_pl = 4,
		_colpl_plath = 5, // preload latch
		_colpl_platl = 6,
		_colpl_platc = 7,
		_coll_ph = 8, // load (aka load next, display current)
		_coll_pl = 9,
		_coll_plath = 10, // preload latch
		_coll_platl = 11,
		_coll_platc = 12,
		_row_complete = 13;

	always @(posedge clk) begin
		if (rst == 1) begin
			lat <= 0; oe <= 1; oclk <= 0; safe_flip <= 0;
			column <= 0;
			cycle <= 0;
			row <= 0;
			state <= _load_addr;
		end else begin
			case (state)
				_load_addr: begin
					// during this state wait for the address signals to
					// propagate to the output of the regsters.
					lat <= 0; oe <= 1; oclk <= 0; safe_flip <= 0;
					state <= _load_value;
				end
				_load_value: begin
					// during this state wait for the bram to fetch and buffer
					// the addressed value on its output.
					lat <= 0; oe <= 1; oclk <= 0; safe_flip <= 0;
					state <= _load_encode;
				end
				_load_encode: begin
					// during this state wait for the ecoded value to hit the
					// output, update the column count.
					lat <= 0; oe <= 1; oclk <= 0; safe_flip <= 0;
					state <= _colpl_ph;
					// update the column addr
					if (column >= columns - 1) begin
						column <= 0;
					end else begin
						column <= column + 1;
					end
				end

				//
				// Preload phase
				//
				_colpl_ph: begin
					lat <= 0; oe <= 1; oclk <= 1; safe_flip <= 0;
					state <= _colpl_pl;
				end
				_colpl_pl: begin
					lat <= 0; oe <= 1; oclk <= 0; safe_flip <= 0;
					// Setup the column inc so that the outputs are valid in
					// three states time
					if (column == columns - 1) begin
						column <= 0;
					end else begin
						column <= column + 1;
					end
					// move out of load after the last bit. This is not when
					// column wraps, but the first cycle after it wraps
					if (column == 0) begin
						state <= _colpl_plath;
					end else begin
						state <= _colpl_ph;
					end
				end
				_colpl_plath: begin
					lat <= 0; oe <= 1; oclk <= 0; safe_flip <= 0;
					// increment the cycle so that it is valid in 2 states
					// time
					column <= 0;
					if (cycle == _depthcount - 1) begin
						cycle <= 0;
					end else begin
						cycle <= cycle + 1;
					end
					state <= _colpl_platl;
				end
				_colpl_platl: begin
					// latch the just loaded values
					lat <= 1; oe <= 1; oclk <= 0; safe_flip <= 0;
					state <= _colpl_platc;
				end
				_colpl_platc: begin
					// clear cycle, transition between lat->oe
					lat <= 0; oe <= 1; oclk <= 0; safe_flip <= 0;
					state <= _coll_ph;
					column <= column + 1;
				end
				//
				// Pipelined load and OE display phase
				//
				_coll_ph: begin
					lat <= 0; oe <= 0; oclk <= 1; safe_flip <= 0;
					state <= _coll_pl;
				end
				_coll_pl: begin
					lat <= 0; oe <= 0; oclk <= 0; safe_flip <= 0;
					// Setup the column inc so that the outputs are valid in
					// two states time
					if (column == columns - 1) begin
						column <= 0;
					end else begin
						column <= column + 1;
					end
					if (column == 0) begin
						state <= _coll_plath;
					end else begin
						state <= _coll_ph;
					end
				end
				_coll_plath: begin
					lat <= 0; oe <= 1; oclk <= 0; safe_flip <= 0;
					// increment the cycle so that it is valid in 2 states
					// time
					column <= 0;
					if (cycle >= _depthcount - 1) begin
						cycle <= 0;
					end else begin
						cycle <= cycle + 1;
					end
					state <= _coll_platl;
				end
				_coll_platl: begin
					// latch the just loaded values
					lat <= 1; oe <= 1; oclk <= 0; safe_flip <= 0;
					state <= _coll_platc;
				end
				_coll_platc: begin
					// clear cycle, transition between lat->oe
					lat <= 0; oe <= 1; oclk <= 0; safe_flip <= 0;
					if (cycle == 1) begin
						state <= _row_complete;
					end else begin
						state <= _coll_ph;
						column <= column + 1;
					end
				end

				//
				// Handle completion of horiz refresh, and vert refresh
				//
				_row_complete: begin
					// this state increments addresses and allows for a cycle
					// to flip the frame buffer safely.
					lat <= 0; oe <= 1; oclk <= 0;
					state <= _load_addr;
					column <= 0; // reset counter
					cycle <= 0; // reset counter
					if (row >= rows - 1) begin
						// Next cycle, completed the set of rows
						row <= 0;
						// Each complete set of rows is equivalent to a full
						// vertical refresh of the display.
						//
						// Additionally each full row revolution is when frame
						// buffer switching should occur. This avoids incorrect colour
						// reprensentation as well as tearing. This window
						// for flipping is a single cycle due to the
						// pipelining of the addr counters -> bram ->
						// encoder being synchronous.
						safe_flip <= 1;
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

