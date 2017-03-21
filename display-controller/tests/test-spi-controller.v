
`include "tests/helpers.v"

module test_spi_controller;
	reg clk, rst;
	reg sclk, ss, mosi;
	wire miso;
	wire [2:0] row;
	wire [4:0] column;
	wire [23:0] pixel = 0;
	wire wen;
	reg ready = 0;
	wire loaded;

	spi_controller #(
		.segments(1),
		.rows(8),
		.columns(32),
		.bitwidth(8)
	) u_controller (
		.clk(clk),
		.rst(rst),
		.sclk(sclk),
		.ss(ss),
		.mosi(mosi),
		.miso(miso),
		.wrow(row),
		.wcol(column),
		.wen(wen),
		.wdata(pixel),
		.ready(ready),
		.loaded(loaded)
	);

	// 5/5ns clock (10ns period)
	always
		# 5 clk = !clk;

	task clkword;
		input [7:0] x;
		integer i;
		begin
			$display("[SPI] write 0x%h to mosi", x);
			for (i = 0; i < 8; i = i + 1) begin
				sclk <= 0;
				@(posedge clk); mosi <= x[7 - i];
				@(negedge clk); sclk <= 1;
				@(posedge clk); sclk <= 0;
				@(posedge clk);
			end
		end
	endtask

	initial begin
		integer i, j;

		$dumpfile({"obj/", `__FILE__, ".vcd"});
		$dumpvars(0, test_spi_controller);

		mosi <= 0; sclk <= 0; ss <= 0;
		clk = 0; rst = 1;
		ready <= 0;
		@(negedge clk);
		rst = 0;
		@(posedge clk);

		// load some data into the spi controller
		ready <= 1;
		@(posedge clk);
		ss <= 1; // begin
		clkword(8'hf0);

		for (i = 0; i < 32; i = i + 1) begin
			// pixel 0x0
			clkword(8'hff);
			clkword(8'hff);
			clkword(i[7:0]);
			@(posedge clk);
			`assert_eq(wen, 1);
			`assert_eq(pixel, ({16'hffff, i[7:0]}));
			`assert_eq(row, 0);
			`assert_eq(column, i);
		end
		ss <= 0;

		@(posedge clk);
		@(posedge clk);
		@(posedge clk);
		@(posedge clk);

		ss <= 1; // begin
		clkword(8'hf0);
		for (i = 0; i < 32; i = i + 1) begin
			clkword(8'h00);
			clkword(8'hed);
			clkword(i[7:0]);
			@(posedge clk);
			`assert_eq(wen, 1);
			`assert_eq(pixel, ({16'h00ed, i[7:0]}));
			`assert_eq(row, 1);
			`assert_eq(column, i);
		end
		ss <= 0;

		@(posedge clk);
		@(posedge clk);
		@(posedge clk);
		@(posedge clk);

		for (j = 2; j < 8; j = j + 1) begin
			ss <= 1; // begin
			clkword(8'hf0);
			for (i = 0; i < 32; i = i + 1) begin
				clkword(j[7:0]);
				clkword(8'hed);
				clkword(i[7:0]);
				@(posedge clk);
				`assert_eq(wen, 1);
				`assert_eq(pixel, ({j[7:0], 8'h00ed, i[7:0]}));
				`assert_eq(row, j);
				`assert_eq(column, i);
			end
			ss <= 0;
			@(posedge clk);
		end

		@(posedge clk);
		@(posedge clk);
		@(posedge clk);
		@(posedge clk);

		ss <= 1;
		clkword(8'h10);
		ss <= 0;
		@(posedge clk); // testing for ss
		@(posedge clk); // got cmd
		@(posedge clk); // process eot
		`assert_eq(loaded, 1);

		# 100
		ss <= 0;

		$finish(0);
	end
endmodule

