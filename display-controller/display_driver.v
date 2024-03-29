//
// PWM Display Driver control machine
// ----------------------------------
//
// This module is intended to be used as a full control component that accepts
// pixel intensity data and outputs to a serial latched row/col driver display
// (e.g. LED Pixel Displays).
//
// This driver is not pipelined and slows down by load_delay to account for
// delays in reading from memory, processing pixel data to intensity before
// being available for pwm comparison.
//
// The module handles brightness based intensity display by setting the row
// bits and pulsing them based on their value compared against a PWM row
// global counter. This means that each column needs to be latched for each
// pulse cycle.
//

module display_driver (clk, rst, frame_complete, row, column, pixel, rgb, oe, lat, oclk);
	parameter integer load_delay = 1; // number of cycles it takes to load from memory
	parameter integer segments = 1;
	parameter integer rows = 8; // number of addressable rows
	parameter integer columns = 32; // number of bits per line
	parameter integer bitwidth = 8;

	input wire clk, rst;

	// Color Correction (gamma correction)
	input wire [((bitwidth * 3) * segments) - 1:0] pixel;
	output reg [(3 * segments) - 1:0] rgb;
	output reg oe, lat, oclk;

	// row, column counter
	output reg [$clog2(rows) - 1:0] row;
	integer column_counter;
	output wire [$clog2(columns) - 1:0] column;
	assign column = column_counter[0 +:$clog2(columns)];

	// pwm cycle counter (must have one more bit to store a post stage)
	reg [bitwidth:0] cycle = 0;

	// RGB pixel values to bits
	integer i = 0, c = 0;
	always @(posedge clk) begin
		if (rst == 1) begin
			rgb <= {(3 * segments){1'b0}};
		end else begin
			for (i = 0; i < segments; i = i + 1) begin
				for (c = 0; c < 3; c = c + 1) begin
					rgb[(3 * i) + c] <=
						(pixel[(bitwidth * 3 * i) + (bitwidth * c) +:bitwidth] >= cycle[0 +:bitwidth]) &&
						(pixel[(bitwidth * 3 * i) + (bitwidth * c) +:bitwidth] != 0);
				end
			end
		end
	end

	// fsm1 -> load columns and latch
	//
	// Sync chain
	// [addr set]
	//           [bram load]
	//                      [pixel correct]
	//                                     [rgb buffered]
	//
	// This can be pipelined such that during each set the rgb output is
	// changed.
	//
	// A = addr is valid
	// P = bram frame buffer has output valid (load_delay + 1)
	// C = corrected pixel is valid (load_delay + 2)
	// R = rgb bit outputs are valid
	// -_ = indicates the oclk high->low pulse
	//
	// APCR-_
	//   APCR-_
	//     APCR-_
	//      .....
	//         APCR-_
	//           APCR-_
	// APCR-_-_-_....-_-_ |
	//    R R R R     R
	// 0 1 2 3 4
	//
	// * address for next pixel is updated by the B state so that it is valid
	//   on the P state.
	// * in order to achieve oclk at /2 clk, the R state triggers a valid
	//   state which allows for the states to trigger inversions of the oclk.
	//
	integer fsm1_state = 0;
	integer load_delay_counter = 0;
	reg load_complete = 0;
	parameter
		_fsm1_hold = 0,
		_fsm1_wait = 1,
		_fsm1_addr = 2,
		_fsm1_rgbbits = 5,
		_fsm1_push = 6,
		_fsm1_push_hold = 7;

	always @(posedge clk) begin
		if (rst == 1) begin
			oclk <= 0;
			column_counter <= 0;
			load_complete <= 0;
			load_delay_counter <= 0;
			fsm1_state <= _fsm1_wait;
		end else begin
			oclk <= (fsm1_state == _fsm1_rgbbits || fsm1_state == _fsm1_push_hold);
			case (fsm1_state)
				_fsm1_hold: begin
					if (push_row == 0) begin
						fsm1_state <= _fsm1_wait;
					end
					load_complete <= 1;
				end
				_fsm1_wait: begin
					if (push_row == 1) begin
						fsm1_state <= _fsm1_addr;
					end
					column_counter <= 0;
					load_complete <= 0;
				end
				_fsm1_addr: begin
					if (load_delay_counter >= load_delay) begin
						fsm1_state <= _fsm1_rgbbits;
						load_delay_counter <= 0;
						column_counter <= column_counter + 1;
					end else begin
						load_delay_counter <= load_delay_counter + 1;
					end
				end
				_fsm1_rgbbits: begin
					fsm1_state <= _fsm1_push;
				end
				_fsm1_push: begin
					fsm1_state <= _fsm1_push_hold;
					column_counter <= column_counter + 1;
				end
				_fsm1_push_hold: begin
					if (column_counter >= columns) begin
						fsm1_state <= _fsm1_hold;
						column_counter <= 0;
					end else begin
						fsm1_state <= _fsm1_push;
					end
					load_complete <= 0;
				end
				default: fsm1_state <= _fsm1_wait;
			endcase
		end
	end

	// fsm2 -> load row, handle oe enable for cycles
	//
	// This fsm drives the cycle and oe whilst triggering the fsm1 to drive
	// the row loading and latching
	//
	// The process begins by first loading the first cycle state of data into
	// the row bits, then the cycle is incremented and the second state
	// enables the display (OE high) for the previous cycle.
	//
	// This fsm must control the latch due to also controlling oe, oe must be
	// off while latching.
	//
	// C = cycle valid
	// R = row loaded
	// Ll = latch pulse
	// O = oe enabled (during states)
	//
	//  C...R
	//       Ll
	//        C...R (O)
	//             Ll
	//              C...R (O)
	//                   Ll
	// ...
	//                    C...R (0)
	//                         Ll
	//                          C...R (O) <- dummy load of cycle 0
	//
	integer fsm2_state = 0;
	reg cycle_complete = 0;
	reg push_row = 0;
	parameter
		_fsm2_hold = 0,
		_fsm2_wait = 1,
		_fsm2_load = 2,
		_fsm2_load_wait = 3,
		_fsm2_latch = 4,
		_fsm2_latch_hold = 5;

	always @(posedge clk) begin
		if (rst == 1) begin
			lat <= 0;
			oe <= 0;
			cycle <= 0;
			cycle_complete <= 0;
			push_row <= 0;
			fsm2_state <= _fsm1_wait;
		end else begin
			case (fsm2_state)
				_fsm2_hold: begin
					if (push_cycle == 0) begin
						fsm2_state <= _fsm2_wait;
					end
					cycle_complete <= 1;
				end
				_fsm2_wait: begin
					if (push_cycle == 1) begin
						fsm2_state <= _fsm2_load;
					end
					cycle <= 0;
					cycle_complete <= 0;
				end
				_fsm2_load: begin
					fsm2_state <= _fsm2_load_wait;
					push_row <= 1; // start the row load
				end
				_fsm2_load_wait: begin
					if (load_complete == 1) begin
						// a cycle of 2^bitwidth is the dummy state that
						// represents displaying the previously loaded state
						// for the valid output length
						if (cycle >= (2 ** bitwidth)) begin
							fsm2_state <= _fsm2_hold;
							cycle <= 0;
						end else begin
							fsm2_state <= _fsm2_latch;
							cycle <= cycle + 1;
						end
						oe <= 0; // low for latch and low for complete
					end
					push_row <= 0;
				end
				_fsm2_latch: begin
					fsm2_state <= _fsm2_latch_hold;
					lat <= 1;
				end
				_fsm2_latch_hold: begin
					fsm2_state <= _fsm2_load;
					lat <= 0;
					// the changing of lat -> 0 and oe -> 1 should be
					// acceptable here since the values being latched are
					// un-changing such that the outputs will always be the
					// same value
					oe <= 1;
				end
				default: fsm2_state <= _fsm2_wait;
			endcase
		end
	end

	// fsm3 -> load rows, handle frame complete
	//
	// This fsm drives the changing of rows and starting the cycle/col fsm's.
	//
	// R = row valid
	// C = cycle display complete
	//
	//
	// R....C
	//       R....C
	// ...
	//             R....C |
	//
	integer fsm3_state = 0;
	output reg frame_complete = 0;
	reg push_cycle = 0;
	parameter
		_fsm3_hold = 0,
		_fsm3_wait = 1,
		_fsm3_cycle = 2,
		_fsm3_cycle_wait = 3;

	always @(posedge clk) begin
		if (rst == 1) begin
			row <= 0;
			frame_complete <= 0;
			push_cycle <= 0;
			fsm3_state <= _fsm1_wait;
		end else begin
			case (fsm3_state)
				_fsm3_hold: begin
					fsm3_state <= _fsm3_wait;
					frame_complete <= 1;
				end
				_fsm3_wait: begin
					fsm3_state <= _fsm3_cycle;
					row <= 0;
					frame_complete <= 0;
				end
				_fsm3_cycle: begin
					fsm3_state <= _fsm3_cycle_wait;
					push_cycle <= 1; // start the cycle display
				end
				_fsm3_cycle_wait: begin
					if (cycle_complete == 1) begin
						if (row + 1 >= rows) begin
							fsm3_state <= _fsm3_hold;
							row <= 0;
						end else begin
							fsm3_state <= _fsm3_cycle;
							row <= row + 1;
						end
					end
					push_cycle <= 0;
				end
				default: fsm3_state <= _fsm3_wait;
			endcase
		end
	end

endmodule

