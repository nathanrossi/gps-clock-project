
`include "tests/helpers.v"

module test_display_driver_simple;
	reg clk, rst;
	wire [2:0] row;
	wire [4:0] column;
	reg [23:0] pixel;
	wire frame_complete, oe, lat, oclk;

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
		.oe(oe),
		.lat(lat),
		.oclk(oclk)
	);

	// 5/5ns clock (10ns period)
	always
		# 5 clk = !clk;

	integer i, in, inn, r, k, kn;
	initial begin
		$dumpfile({"obj/", `__FILE__, ".vcd"});
		$dumpvars(0, test_display_driver_simple);

		pixel <= {24{1'b0}};
		clk = 0;
		rst = 1;
		@(negedge clk)
		rst = 0;

		`define display_state(state) \
			$display("[%t] {%10s} %4d/(%4d)/%4d | %2dx%2d, OE(%d) LAT(%d) OCLK(%d) SF(%d) | B:%2d(%2d)", $time, state, r, kn, k, row, column, oe, lat, oclk, frame_complete, i, in)

		// this does not assume any clock timings.

		for (r = 0; r < 16; r = r + 1) begin
			pixel <= {24{r[0]}};

			for (k = 0; k < 256 + 1; k = k + 1) begin // 1 pre, 256 display (1 dummy load)
				kn = (k + 1);
				for (i = 0; i < 32; i = i + 1) begin
					in = (i + 1);
					inn = (in + 1);
					@(posedge oclk);
					`display_state("col+");
					`assert_eq(column, inn[4:0]); // pipeline should have next column in register
					`assert_eq(row, r);
					`assert_eq(lat, 0);
					`assert_eq(oe, (k != 0));
					`assert_eq(frame_complete, 0);
					@(negedge oclk);
					`display_state("col-");
					`assert_eq(row, r);
					`assert_eq(lat, 0);
					`assert_eq(oe, (k != 0));
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

