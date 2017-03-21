
module test_top_load_spi;
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
				@(posedge clk); mosi <= x[7 - i];
				@(negedge clk); sclk <= 1;
				@(posedge clk); sclk <= 0;
				@(posedge clk);
			end
		end
	endtask

	integer i = 0;
	initial begin
		$dumpfile({"obj/", `__FILE__, ".vcd"});
		$dumpvars(0, test_top_load_spi);

		// This test case is for observation only, and does not assert or
		// validate any changes.

		# 2000000
		// load some data into the memory
		ss <= 0;
		clkword(8'hf0);
		clkword(8'hff);
		clkword(8'h00);
		clkword(8'hff);
		@(posedge clk);
		ss <= 1;

		# 20000000
		ss <= 1;

		@(posedge clk);
		ss <= 0;
		clkword(8'hf0);
		clkword(8'hff);
		clkword(8'h00);
		clkword(8'hff);
		@(posedge clk);
		ss <= 1;

		# 2000000
		ss <= 1;

		$finish(0);
	end
endmodule

