`include "tests/helpers.v"

module test_display_driver_row_loader;
	reg clk = 0, rst = 0;
	reg load = 0;
	wire complete;
	wire oclk;
	wire pipe;
	wire [$clog2(32) - 1:0] column;

	display_driver_row_loader #(
		.pipe_length(2),
		.columns(32),
		.bitwidth(8)
	) u_loader (
		.clk(clk),
		.rst(rst),
		.load(load),
		.complete(complete),
		.oclk(oclk),
		.pipe(pipe),
		.column(column[$clog2(32) - 1:0])
	);

	// 5/5ns clock (10ns period)
	always
		# 5 clk = !clk;

	initial begin
		integer i = 0;
		`setup_vcd(test_display_driver_row_loader);

		rst <= 0;
		load <= 0;

		@(posedge clk);
		@(negedge clk);


		// check control timing for a load
		load <= 1;
		`assert_eq(complete, 0);
		`assert_eq(column, 0);
		`assert_eq(pipe, 0);
		`assert_eq(oclk, 0);

		@(negedge clk);
		// load col 0
		`assert_eq(complete, 0);
		`assert_eq(column, 1);
		`assert_eq(pipe, 1);
		`assert_eq(oclk, 0);
		@(negedge clk);
		// load col 1
		`assert_eq(complete, 0);
		`assert_eq(column, 2);
		`assert_eq(pipe, 1);
		`assert_eq(oclk, 0);

		$display("assertion, col's 0 and 1 are in the 2 length pipe");

		@(negedge clk);
		// col 0 valid, pipe stops, load col 2
		`assert_eq(complete, 0);
		`assert_eq(column, 3);
		`assert_eq(pipe, 0);
		`assert_eq(oclk, 0);

		$display("assertion, col 2 in pipe, ");

		@(negedge clk);
		// col 0 valid expect no oclk
		`assert_eq(complete, 0);
		`assert_eq(column, 3);
		`assert_eq(pipe, 1);
		`assert_eq(oclk, 1);

		i = 3;
		repeat (31) begin
			i = i + 1;
			$display("assertion, checking cycle depth %d", i);
			@(negedge clk);
			`assert_eq(complete, 0);
			`assert_eq(column, i[$clog2(32) - 1:0]);
			`assert_eq(pipe, 0);
			`assert_eq(oclk, 0);
			@(negedge clk);
			`assert_eq(complete, 0);
			`assert_eq(column, i[$clog2(32) - 1:0]);
			`assert_eq(pipe, 1);
			`assert_eq(oclk, 1);
		end

		@(negedge clk);
		`assert_eq(complete, 1);
		`assert_eq(column, 0);
		`assert_eq(pipe, 0);
		`assert_eq(oclk, 0);

		# 100
		$finish(0);
	end
endmodule

