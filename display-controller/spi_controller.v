
module spi_controller(clk, rst, sclk, ss, mosi, miso, wdata, wen, wrow, wcol, ready, loaded);
	parameter segments = 1;
	parameter rows = 8; // number of addressable rows
	parameter columns = 32; // number of bits per line
	parameter bitwidth = 8;

	input wire clk, rst;

	input wire sclk, ss, mosi;
	output wire miso;

	output reg [(segments * bitwidth * 3) - 1:0] wdata = 0;
	output reg [$clog2(rows) - 1:0] wrow = 0;
	output reg [$clog2(columns) - 1:0] wcol = 0;

	reg integer column = 0;
	reg integer channel = 0;
	output reg wen = 0;

	input wire ready;

	// buffer load logic
	parameter
		_cmd_invalid = 0,
		_cmd_load_row = 1,
		_cmd_end = 2;

	reg started = 0;
	reg integer cmd = 0;
	output reg loaded = 0;
	reg complete = 0;

	reg last_ready = 0;
	reg mem_ready = 0;

	wire [7:0] load_data;
	wire load_valid;

	reg [5:0] ss_buf;

	always @(posedge clk) begin
		if (rst == 1) begin
			started <= 0;
			loaded <= 0;
			complete <= 0;
			column <= 0;
			channel <= 0;
			cmd <= 0;
			wen <= 0;

			last_ready <= 0;
			mem_ready <= 0;
		end else begin
			// wen is low otherwise
			wen <= 0;

			// buffer the ss bits (TODO: move this to the spi-slave)
			ss_buf <= {ss_buf[4:0], ss};

			// check for frame flip, when ready goes 0 -> 1
			if (ready == 1 && last_ready == 0) begin
				mem_ready <= 1;
			end else if (ready == 0) begin
				mem_ready <= 0;
			end
			last_ready <= ready;

			if (started == 0) begin
				// check command, needs to be 0xfx where x = row
				if (load_valid == 1) begin
					started <= 1;
					if (load_data[7:4] == 4'hf) begin
						// start of load
						channel <= 0;
						column <= 0;
						wrow <= load_data[3:0];
						cmd <= _cmd_load_row;
					end else if (load_data == 8'h10) begin
						cmd <= _cmd_end;
					end else begin
						cmd <= _cmd_invalid;
					end

					// if the last command was a completion, and mem_ready,
					// allow writing and more complete marking
					if (complete == 1 && mem_ready == 1) begin
						complete <= 0;
					end
				end

				// the loaded signal is only high for one cycle, to tell the
				// flipper that the memory was populated for flipping
				loaded <= 0;
			end else if (started == 1) begin
				case (cmd)
					_cmd_load_row: begin
						// only load on valid and when not complete
						if (load_valid && (complete == 0)) begin
							// serial load into the wdata reg, dropping the oldest
							wdata <= {wdata[(segments * bitwidth * 3) - bitwidth - 1:0], load_data};

							if (channel == ((segments * 3) - 1)) begin
								wcol <= column;
								wen <= 1;

								channel <= 0;
								// loaded each segment, next column
								if (column == (columns - 1)) begin
									column <= 0;
								end else begin
									column <= column + 1;
								end
							end else begin
								channel <= channel + 1;
							end
						end
					end
					_cmd_end: begin
						if (ss == 0) begin
							complete <= 1;
							loaded <= (complete == 0);
						end
					end
				endcase

				// end of command
				if (ss_buf == 6'b110000) begin
					started <= 0;
					cmd <= _cmd_invalid;
				end
			end
		end
	end

	spi_slave u_spi_slave (
		.clk(clk),
		.rst(rst),
		.sclk(sclk),
		.ss(ss),
		.mosi(mosi),
		.miso(miso),
		.data(load_data),
		.valid(load_valid)
	);

endmodule

