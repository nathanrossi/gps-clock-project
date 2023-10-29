// Data Loader
// ===========
//
// Loads data into the display memory from an async source of where data is
// input as commands via the idata and ivalid signals
//
// Commands:
//   0xf? - Load row, where the row is defined as the lower 4 bits of the
//          command. This command must be followed by exactly column number of
//          data words, where the word size is equal to the number of bits in
//          memory for each pixel (aka segments * bitwidth * 3).
//   0x10 - End command, or display flip. This triggers the display to flip
//          which memory buffer is used, and causes the loaded data to be
//          displayed.
//
// Interface to memory:
//  wdata  - data to write (bitwidth * 3)
//  wrow   - row to write data to
//  wcol   - column to write data to
//  wen    - enable data write, write data on next cycle
//  ready  - memory is ready to write
//  loaded - frame is loaded

module data_loader(clk, rst, idata, ivalid, wdata, wen, wrow, wcol, ready, loaded);
	parameter segments = 1;
	parameter rows = 8; // number of addressable rows
	parameter columns = 32; // number of bits per line
	parameter bitwidth = 8;

	input wire clk, rst;

	output reg [(segments * bitwidth * 3) - 1:0] wdata = 0;
	output reg [$clog2(rows) - 1:0] wrow = 0;
	output reg [$clog2(columns) - 1:0] wcol = 0;

	integer column = 0;
	integer channel = 0;
	output reg wen = 0;

	input wire ready;

	// buffer load logic
	parameter
		_cmd_wait = 0,
		_cmd_load_row = 1;

	integer cmd = 0;
	reg dummy_write = 0;

	output reg loaded = 0;

	input wire [7:0] idata;
	input wire ivalid;

	always @(posedge clk) begin
		if (rst == 1) begin
			loaded <= 0;
			column <= 0;
			channel <= 0;
			cmd <= 0;
			wen <= 0;
		end else begin
			// wen is low otherwise
			wen <= 0;

			if (cmd == _cmd_wait) begin
				// the loaded signal is only high for one cycle, to tell the
				// flipper that the memory was populated for flipping
				loaded <= 0;

				// check command, needs to be 0xfx where x = row
				if (ivalid == 1) begin
					if (idata[7:4] == 4'hf) begin
						// start of load
						channel <= 0;
						column <= 0;
						wrow <= idata[3:0];
						cmd <= _cmd_load_row;
						dummy_write <= ready; // use the ready state from the start of the load
					end else if (idata == 8'h10) begin
						// mark the frame as loaded for flip
						if (ready == 1) begin
							loaded <= 1;
						end
					end
				end
			end else if (cmd == _cmd_load_row) begin
				// only load on valid and when not complete
				if (ivalid == 1) begin
					// serial load into the wdata reg, dropping the oldest
					wdata <= {wdata[(segments * bitwidth * 3) - bitwidth - 1:0], idata};

					if (channel == ((segments * 3) - 1)) begin
						wcol <= column;
						// if this command is being processed whilst the
						// memory is not ready, then don't assert the wen = 1
						wen <= dummy_write;

						channel <= 0;
						// loaded each segment, next column
						if (column == (columns - 1)) begin
							column <= 0;
							cmd <= _cmd_wait;
						end else begin
							column <= column + 1;
						end
					end else begin
						channel <= channel + 1;
					end
				end
			end else begin
				cmd <= _cmd_wait;
			end
		end
	end

endmodule

