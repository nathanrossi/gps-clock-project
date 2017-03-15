
`include "tests/helpers.v"

module test_display_driver_mod2_simple;
	reg clk, rst;
	wire [2:0] row;
	wire [4:0] column;
	wire [7:0] cycle;
	wire safe_flip, oe, lat, oclk;

	display_driver_mod2 #(
		.rows(8),
		.columns(32),
		.bitdepth(8)
	) u_driver (
		.clk(clk),
		.rst(rst),
		.row(row),
		.column(column),
		.cycle(cycle),
		.safe_flip(safe_flip),
		.oe(oe),
		.lat(lat),
		.oclk(oclk)
	);

	// 5/5ns clock (10ns period)
	always
		# 5 clk = !clk;

	integer i, in, r, k, kn;
	initial begin
		$dumpfile({"obj/", `__FILE__, ".vcd"});
		$dumpvars(0, test_display_driver_mod2_simple);

		clk = 0;
		rst = 1;
		@(negedge clk)
		rst = 0;

		`define display_state(state) \
			$display("[%t] {%10s} C:%4d/%4d(%4d) | %2dx%2d, OE(%d) LAT(%d) OCLK(%d) SF(%d) | B:%2d(%2d)", $time, state, cycle, k, kn, row, column, oe, lat, oclk, safe_flip, i, in)

		// this does not assume any clock timings.

		for (r = 0; r < 16; r = r + 1) begin
			for (k = 0; k < 257; k = k + 1) begin
				kn = (k + 1);
				for (i = 0; i < 32; i = i + 1) begin
					in = (i + 1);
					@(posedge oclk);
					`display_state("col ph");
					`assert_eq(column, in[4:0]); // pipeline should have next column in register
					`assert_eq(row, r);
					`assert_eq(lat, 0);
					`assert_eq(oe, (k != 0));
					`assert_eq(safe_flip, 0);
					@(negedge oclk);
					`display_state("col pl");
					`assert_eq(row, r);
					`assert_eq(lat, 0);
					`assert_eq(oe, (k != 0));
					`assert_eq(safe_flip, 0);
				end

				@(posedge lat); // latch
				`display_state("latch ph");
				`assert_eq(oe, 0);
				`assert_eq(oclk, 0);
				`assert_eq(safe_flip, 0);
				@(negedge lat); // release
				`display_state("latch pl");
				`assert_eq(cycle, kn[7:0]); // pipeline should have next cycle in register
				//`assert_eq(column, 0); // pipeline should have next column in register
				`assert_eq(oe, 0);
				`assert_eq(oclk, 0);
				`assert_eq(safe_flip, 0);
			end

			if (r == 7) begin
				@(posedge safe_flip);
				$display("safe flip asserted");
				`assert_eq(lat, 0);
				`assert_eq(oe, 0);
				`assert_eq(oclk, 0);
			end
		end

		$finish(0);
	end
endmodule

