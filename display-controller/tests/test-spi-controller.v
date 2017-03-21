
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
		integer i;

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
		// pixel 0x0
		clkword(8'hff);
		clkword(8'hff);
		clkword(8'hff);
		@(posedge clk);
		`assert_eq(wen, 1);
		`assert_eq(pixel, 24'hffffff);
		`assert_eq(row, 0);
		`assert_eq(column, 0);
		// pixel 1x0
		clkword(8'hff);
		clkword(8'h00);
		clkword(8'hff);
		@(posedge clk);
		`assert_eq(wen, 1);
		`assert_eq(pixel, 24'hff00ff);
		`assert_eq(row, 0);
		`assert_eq(column, 1);
		// pixel 2x0
		clkword(8'h00);
		clkword(8'hed);
		clkword(8'hff);
		@(posedge clk);
		`assert_eq(wen, 1);
		`assert_eq(pixel, 24'h00edff);
		`assert_eq(row, 0);
		`assert_eq(column, 2);

		for (i = 3; i < 32; i = i + 1) begin
			clkword(8'h00);
			clkword(8'hed);
			clkword(i[7:0]);
			@(posedge clk);
			`assert_eq(wen, 1);
			`assert_eq(pixel, ({16'h00ed, i[7:0]}));
			`assert_eq(row, 0);
			`assert_eq(column, i);
		end

		// pixel 0x1
		clkword(8'h12);
		clkword(8'h34);
		clkword(8'h56);
		@(posedge clk);
		`assert_eq(wen, 1);
		`assert_eq(pixel, 24'h123456);
		`assert_eq(row, 1);
		`assert_eq(column, 0);

		$finish(0);
	end
endmodule

