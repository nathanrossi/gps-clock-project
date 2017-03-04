module test_display_driver_simple;
	reg clk, rst;
	wire [2:0] row;
	wire [4:0] column;
	wire [7:0] cycle;
	wire oe, lat, oclk;


	display_driver #(
		.rows(8),
		.columns(32)
	) u_driver (
		.clk(clk),
		.rst(rst),
		.row(row),
		.column(column),
		.cycle(cycle),
		.oe(oe),
		.lat(lat),
		.oclk(outclk)
	);

	// 5/5ns clock (10ns period)
	always
		# 5 clk = !clk;

	integer i;
	initial begin
		$dumpfile("test.vcd");
		$dumpvars(0,test_display_driver_simple);

		clk = 0;
		rst = 1;
		@(negedge clk)
		rst = 0;

		repeat (32) begin
			$display("[%t] (cycle = %d) R/C: %d x %d, OE = %b, LAT = %b) [row_fetch]", $time, cycle, row, column, oe, lat);
			helpers.assert_eq(column, i);
			helpers.assert_eq(lat, 1);
			helpers.assert_eq(oe, 1);
			helpers.assert_eq(oclk, 0);
			@(negedge clk);

			for (i = 0; i < 32; i = i + 1) begin
				$display("[%t] (cycle = %d) R/C: %d x %d, OE = %b, LAT = %b) [col_fetch %d]", $time, cycle, row, column, oe, lat, i);
				helpers.assert_eq(column, i);
				helpers.assert_eq(lat, 1);
				helpers.assert_eq(oe, 1);
				helpers.assert_eq(oclk, 1);
				@(negedge clk);
				$display("[%t] (cycle = %d) R/C: %d x %d, OE = %b, LAT = %b) [col_load %d]", $time, cycle, row, column, oe, lat, i);
				helpers.assert_eq(column, i);
				helpers.assert_eq(lat, 1);
				helpers.assert_eq(oe, 1);
				helpers.assert_eq(oclk, 0);
				@(negedge clk);
			end

			@(negedge clk); // latch
			$display("[%t] (cycle = %d) R/C: %d x %d, OE = %b, LAT = %b) [latch]", $time, cycle, row, column, oe, lat);
			helpers.assert_eq(lat, 0);
			helpers.assert_eq(oe, 1);
			helpers.assert_eq(oclk, 0);

			repeat (8) begin
				@(negedge clk); // oe enable dewell
				$display("[%t] (cycle = %d) R/C: %d x %d, OE = %b, LAT = %b) [oe dewell]", $time, cycle, row, column, oe, lat);
				helpers.assert_eq(lat, 1);
				helpers.assert_eq(oe, 0);
				helpers.assert_eq(oclk, 0);
			end
			@(negedge clk); // clear
			$display("[%t] (cycle = %d) R/C: %d x %d, OE = %b, LAT = %b) [oe clear]", $time, cycle, row, column, oe, lat);
			helpers.assert_eq(lat, 1);
			helpers.assert_eq(oe, 1);
			helpers.assert_eq(oclk, 0);
		end

		$finish(0);
	end
endmodule

