`include "helpers.v"

module display_driver_simple;
	reg clk, rst;
	wire [2:0] row;
	wire [4:0] column;
	reg [23:0] pixel = 0;
	wire frame_complete, oe, lat, oclk;
	wire [2:0] rgb;

	display_driver #(
		.segments(1),
		.rows(8),
		.columns(32),
		.bitwidth(8)
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
	always
		# 5 clk = !clk;

	// dummy memory
	reg [23:0] pixel_data [0:(32 * 8) - 1];
	always @(posedge clk) begin
		pixel <= pixel_data[{row, column}];
	end

	integer i, in, inn, j, r, k, kn;
	initial begin
		`setup_vcd(display_driver_simple);

		for (j = 0; j < 8; j = j + 1) begin
			for (i = 0; i < 32; i = i + 1) begin
				if (i == 0 && j == 0)
					pixel_data[(j * 32) + i] <= 24'hff0000;
				else
					pixel_data[(j * 32) + i] <= 24'h000000;
			end
		end
		clk = 0;
		rst = 1;
		@(negedge clk)
		rst = 0;

		`define display_state(state) \
			$display("[%t] {%10s} %4d/(%4d)/%4d | %2dx%2d, OE(%d) LAT(%d) OCLK(%d) SF(%d) | B:%2d(%2d)", $time, state, r, kn, k, row, column, oe, lat, oclk, frame_complete, i, in)

		// this does not assume any clock timings (aka delay of components)

		for (r = 0; r < 2; r = r + 1) begin
			for (k = 0; k < 256 + 1; k = k + 1) begin // 1 pre, 256 display (1 dummy load)
				kn = (k + 1);
				for (i = 0; i < 32; i = i + 1) begin
					in = (i + 1);
					inn = (in + 1);
					@(posedge oclk);
					`display_state("col+");
					if (i == 32) begin
						`assert_eq(column, in[4:0]); // pipeline should have next column in register
					end
					`assert_eq(row, r);
					`assert_eq(lat, 0);
					`assert_eq(oe, (k != 0));
					`assert_eq(frame_complete, 0);
					if (r == 0 && i == 0)
						`assert_eq(rgb, 3'b100);
					else
						`assert_eq(rgb, 3'b000);
					@(negedge oclk);
					`display_state("col-");
					`assert_eq(row, r);
					`assert_eq(lat, 0);
					//`assert_eq(oe, (k != 0));
					`assert_eq(frame_complete, 0);
				end

				if (k != 256) begin
					@(posedge lat);
					`display_state("latch");
					`assert_eq(oe, 0); // detect bad state during initial latch
					`assert_eq(oclk, 0);
					`assert_eq(frame_complete, 0);
					@(negedge lat);
					`assert_eq(oe, 1); // oe should display
					`assert_eq(oclk, 0);
					`assert_eq(frame_complete, 0);
				end else begin
					@(negedge oe); // on the last cycle there is no latching
					`display_state("load-end");
					`assert_eq(oclk, 0);
					`assert_eq(frame_complete, 0);
				end
			end

			if (r == 7) begin
				@(posedge frame_complete);
				$display("safe flip asserted");
				`assert_eq(lat, 0);
				`assert_eq(oe, 0);
				`assert_eq(oclk, 0);
			end
		end

		$finish(0);
	end
endmodule

