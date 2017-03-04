module test_display_driver_simple;
	reg clk, rst;
	wire [2:0] row;
	wire [4:0] column;
	wire [7:0] cycle;
	wire safe_flip, oe, lat, oclk;


	display_driver #(
		.rows(8),
		.columns(32),
		.cycles(256)
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

	integer i, in, r, k;
	initial begin
		$dumpfile("test.vcd");
		$dumpvars(0,test_display_driver_simple);

		clk = 0;
		rst = 1;
		@(negedge clk)
		rst = 0;

		// this does not assume any clock timings.

		for (k = 0; k < 257; k = k + 1) begin
			for (r = 0; r < 8; r = r + 1) begin
				for (i = 0; i < 32; i = i + 1) begin
					in = (i + 1);
					@(posedge oclk);
					$display("[%t] (cycle = %d//%d) R/C: %d x %d, OE(%b), LAT(%b), OCLK(%b), SF(%b)) [col ph %d]", $time, cycle, k, row, column, oe, lat, oclk, safe_flip, i);
					helpers.assert_eq(column, in[4:0]); // pipeline should have next column in register
					helpers.assert_eq(row, r);
					helpers.assert_eq(lat, 1);
					helpers.assert_eq(oe, 1);
					helpers.assert_eq(safe_flip, 0);
					@(negedge oclk);
					$display("[%t] (cycle = %d//%d) R/C: %d x %d, OE(%b), LAT(%b), OCLK(%b), SF(%b)) [col pl %d]", $time, cycle, k, row, column, oe, lat, oclk, safe_flip, i);
					helpers.assert_eq(row, r);
					helpers.assert_eq(lat, 1);
					helpers.assert_eq(oe, 1);
					helpers.assert_eq(safe_flip, 0);
				end

				@(negedge lat); // latch
				$display("[%t] (cycle = %d) R/C: %d x %d, OE = %b, LAT = %b) [latch]", $time, cycle, row, column, oe, lat);
				helpers.assert_eq(oe, 1);
				helpers.assert_eq(oclk, 0);
				helpers.assert_eq(safe_flip, 0);
				@(posedge lat); // release
				$display("[%t] (cycle = %d) R/C: %d x %d, OE = %b, LAT = %b) [latch]", $time, cycle, row, column, oe, lat);
				helpers.assert_eq(oe, 1);
				helpers.assert_eq(oclk, 0);
				helpers.assert_eq(safe_flip, 0);

				@(negedge oe) // oe low
				$display("[%t] (cycle = %d) R/C: %d x %d, OE = %b, LAT = %b) [oe dewell]", $time, cycle, row, column, oe, lat);
				helpers.assert_eq(lat, 1);
				helpers.assert_eq(oclk, 0);
				helpers.assert_eq(safe_flip, 0);
				@(posedge oe); // oe release
				$display("[%t] (cycle = %d) R/C: %d x %d, OE(%b), LAT(%b), OCLK(%b), SF(%b)) [oe dewell]", $time, cycle, row, column, oe, lat, oclk, safe_flip);
				helpers.assert_eq(lat, 1);
				helpers.assert_eq(oclk, 0);
			end

			if (k == 255) begin
				@(posedge safe_flip);
				$display("safe flip asserted");
				helpers.assert_eq(lat, 1);
				helpers.assert_eq(oe, 1);
				helpers.assert_eq(oclk, 0);
			end
		end

		$finish(0);
	end
endmodule

