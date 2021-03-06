`include "helpers.v"

module top_load_spi;
	reg clk = 0;
	reg sclk = 0;
	reg ss = 1;
	reg mosi = 0;
	wire miso;

	top u_top (
		.clk(clk),
		.spi_sclk(sclk),
		.spi_ss(ss),
		.spi_mosi(mosi),
		.spi_miso(miso)
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
				@(posedge clk); mosi <= x[i];
				@(negedge clk); sclk <= 1;
				@(posedge clk); sclk <= 0;
				@(posedge clk);
			end
		end
	endtask

	integer i = 0;
	initial begin
		`setup_vcd(top_load_spi);

		// This test case is for observation only, and does not assert or
		// validate any changes.

		# 2000000
		// load some data into the memory
		ss <= 0;
		clkword(8'hf0);
		for (i = 0; i < 32; i = i + 1) begin
			clkword(8'hff);
			clkword(i[7:0]);
			clkword(8'hff);
			@(posedge clk);
		end
		ss <= 1;

		@(posedge clk);
		@(posedge clk);
		@(posedge clk);
		@(posedge clk);

		ss <= 0;
		clkword(8'h10);
		ss <= 1;

		# 20000000
		ss <= 1;

		ss <= 0;
		clkword(8'hf0);
		for (i = 0; i < 32; i = i + 1) begin
			clkword(8'hff);
			clkword(i[7:0]);
			clkword(8'hff);
			@(posedge clk);
		end
		ss <= 1;

		@(posedge clk);
		@(posedge clk);
		@(posedge clk);
		@(posedge clk);

		ss <= 0;
		clkword(8'h10);
		ss <= 1;

		# 2000000
		ss <= 1;

		$finish(0);
	end
endmodule

