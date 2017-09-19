`include "helpers.v"

`timescale 1 ns / 1 ps
module display_driver_timing;
	reg clk, rst;
	wire [2:0] row;
	wire [4:0] column;
	reg [(10 * 3) - 1:0] pixel = 0;
	wire frame_complete, oe, lat, oclk;
	wire [2:0] rgb;

	display_driver #(
		.segments(1),
		.rows(8),
		.columns(32),
		.bitwidth(10)
	) u_driver (
		.clk(clk),
		.rst(rst),
		.frame_complete(frame_complete),
		.row(row),
		.column(column),
		.pixel(pixel),
		.rgb(rgb),
		.oe(oe),
		.lat(lat),
		.oclk(oclk)
	);

	// 5/5ns clock (10ns period)
	parameter clkfreq = 48000000;
	parameter period = ((1 * 1000 * 1000 * 1000) / clkfreq);
	always
		# period clk = !clk;

	// dummy memory
	reg integer pixel_cycles [0:(32 * 8) - 1];

	initial begin
		integer i, j, z, t;
		integer frame_count, frame_cycles;
		integer mark_complete;

		`setup_vcd(display_driver_timing);

		pixel <= 24'hffffff; // set all high, to determine full on time
		frame_count = 0;
		frame_cycles = 0;
		mark_complete = 0;
		for (j = 0; j < 8; j = j + 1) begin
			for (i = 0; i < 32; i = i + 1) begin
				pixel_cycles[(j * 32) + i] <= 0;
			end
		end

		clk = 0;
		rst = 1;
		@(negedge clk)
		rst = 0;

		repeat (1) begin
			$display("[%t] info: frame %d", $time, frame_count);
			while (mark_complete == 0) begin
				@(posedge clk);
				frame_cycles = frame_cycles + 1;
				for (z = 0; z < 32; z = z + 1) begin
					if (oe == 1) begin
						// oe is high on this row for +1 cycle
						pixel_cycles[(row * 32) + z] = pixel_cycles[(row * 32) + z] + 1;
					end
				end

				if (frame_complete == 1) begin
					// display timing info for frame
					t = 0;
					for (j = 0; j < 8; j = j + 1) begin
						z = pixel_cycles[(j * 32)];
						t = t + z;
						$display("[%t] info: row     %3d = %d/%d, %d %%", $time, j, z, frame_cycles, (z * 100) / frame_cycles);
					end
					$display("[%t] info: inter-frame = %d/%d, %d %%", $time, frame_cycles - t, frame_cycles, ((frame_cycles - t) * 100) / frame_cycles);
					$display("[%t] info: frame takes %d cycles, vert %d hz (%d Hz clk)", $time, frame_cycles, (clkfreq / frame_cycles), clkfreq);

					// ensure persistence of vision is kept, this true for >60Hz
					`assert_dge((clkfreq / frame_cycles), 60);

					frame_cycles = 0;
					for (j = 0; j < 8; j = j + 1) begin
						for (i = 0; i < 32; i = i + 1) begin
							pixel_cycles[(j * 32) + i] = 0;
						end
					end
					mark_complete = 1;
				end
			end
			mark_complete = 0;
			frame_count = frame_count + 1;
		end

		$finish(0);
	end
endmodule

