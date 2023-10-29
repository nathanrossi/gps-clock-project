//
// Display Driver control machine
// ------------------------------
//
// This module is intended to be used as a full control component that accepts
// pixel data and outputs to a serial latched row/col driver display (e.g. LED
// Pixel Displays).
//
// This version of the display driver uses pulses which are powers of
// 2 instead of extending the bit depth of the pwm counter. This means more
// time is spent displaying the pixels allows for larger brightness and less
// wasted clock cycles.
//
// This driver does not include any gamma correction, this is left outside the
// driver module. Use load_delay to account for cycle delays caused by any
// correction.
//

module display_driver_pulsewidth (clk, rst, frame_complete, row, column, pixel, rgb, oe, lat, oclk);
	parameter integer load_delay = 1; // number of cycles it takes to load from memory
	parameter integer segments = 1;
	parameter integer rows = 8; // number of addressable rows
	parameter integer columns = 32; // number of bits per line
	parameter integer bitwidth = 8;

	// clock and reset
	input wire clk, rst;

	// input pixel data
	input wire [((bitwidth * 3) * segments) - 1:0] pixel;

	// output control
	output reg frame_complete = 0;

	// output display data/control
	output wire oe, lat, oclk;
	output wire [(3 * segments) - 1:0] rgb;
	output wire [$clog2(columns) - 1:0] column;
	output reg [$clog2(rows) - 1:0] row = 0;

	wire [$clog2(bitwidth) - 1:0] select_bit;

	reg pulse_go = 0;
	wire pulse_complete, pulse_full_complete;

	display_driver_pulse_generator #(
		.bitwidth(bitwidth)
	) u_pulse (
		.clk(clk),
		.rst(rst),
		.go(pulse_go),
		.complete(pulse_complete),
		.full_complete(pulse_full_complete),
		.select(select_bit)
	);

	wire pipe_go;

	display_driver_rgb_pipe #(
		.pipe_length(load_delay),
		.segments(segments),
		.bitwidth(bitwidth)
	) u_pipe (
		.clk(clk),
		.rst(rst),
		.go(pipe_go),
		.select(select_bit),
		.pixel(pixel),
		.rgb(rgb)
	);

	reg row_load = 0;
	wire row_complete;

	display_driver_row_loader #(
		.pipe_length(load_delay),
		.columns(columns)
	) u_loader (
		.clk(clk),
		.rst(rst),
		.load(row_load),
		.complete(row_complete),
		.pipe(pipe_go),
		.column(column),
		.oclk(oclk)
	);

	// State driving
	//
	// Frames are rendered as follows
	//
	//  (0) -> before start
	//  (1) -> inital row_load (complete controls lat signal)
	//  (2) -> wait for row_complete
	//  (3) -> row_load and pulse_gen
	//  (4) -> wait for row_complete and pulse_complete.
	//         (deassert load and pulse when they complete)
	//         When complete:
	//           * last of pulse set increment row, and back to (1)
	//           * if incremented row wraps, assert frame_complete
	//           * back to (3)
	//

	assign lat = row_complete;
	assign oe = ((fsm == _fsm_row_wait) && pulse_go);

	reg pulse_full_completed = 0;
	integer fsm = 0;
	parameter
		_fsm_wait = 0,
		_fsm_irow_load = 1,
		_fsm_irow_wait = 2,
		_fsm_row_load = 3,
		_fsm_row_wait = 4,
		_fsm_row_complete = 5;

	always @(posedge clk) begin
		if (rst == 1) begin
			fsm <= _fsm_wait;
			row_load <= 0;
			pulse_go <= 0;
			row <= 0;
			frame_complete <= 0;
			pulse_full_completed <= 0;
		end else begin
			if (fsm == _fsm_wait) begin
				fsm <= _fsm_irow_load;
			end else begin
				if (fsm == _fsm_irow_load || fsm == _fsm_row_load) begin
					// trigger loading of the row
					row_load <= 1;
					// after first load, start the pulse generator
					if (fsm == _fsm_row_load) begin
						pulse_go <= 1;
					end
					// reset state of pulse fully completed
					pulse_full_completed <= 0;
				end else if (fsm == _fsm_irow_wait || fsm == _fsm_row_wait) begin
					// release row_load/pulse_go if they are complete, this is
					// also used  to detect if one task was already completed
					if (row_complete == 1) begin
						row_load <= 0;
					end
					if (pulse_complete == 1) begin
						pulse_go <= 0;
					end
					// store the pulse fully completed state
					pulse_full_completed <= pulse_full_completed | pulse_full_complete;
				end

				// determine next state to move to
				if (fsm == _fsm_irow_load) begin
					fsm <= _fsm_irow_wait;
					frame_complete <= 0;
				end else if (fsm == _fsm_irow_wait) begin
					// don't wait for the pulse to complete, it wasn't triggered
					if (row_complete == 1) begin
						fsm <= _fsm_row_load;
					end
					frame_complete <= 0;
				end else if (fsm == _fsm_row_load) begin
					fsm <= _fsm_row_wait;
					frame_complete <= 0;
				end else if (fsm == _fsm_row_wait) begin
					// either it just completed, or it was completed
					if ((row_complete == 1 || row_load == 0) && (pulse_complete == 1 || pulse_go == 0)) begin
						if (pulse_full_completed == 1) begin
							// the set of pulses was completed, next row
							fsm <= _fsm_irow_load;
							if (row == rows - 1) begin
								frame_complete <= 1;
								row <= 0;
							end else begin
								frame_complete <= 0;
								row <= row + 1;
							end
						end else begin
							// not a new row
							fsm <= _fsm_row_load;
							frame_complete <= 0;
						end
					end
				end
			end
		end
	end

endmodule

