
`include "tests/helpers.v"

module test_spi_slave_simple;
	reg clk = 0, sclk = 0, rst = 0, ss = 1;
	reg mosi = 0;
	wire miso;
	wire [7:0] data;
	wire valid;

	spi_slave u_spi_slave (
		.clk(clk),
		.rst(rst),
		.sclk(sclk),
		.ss(ss),
		.mosi(mosi),
		.miso(miso),
		.data(data),
		.valid(valid)
	);

	// 5/5ns clock (10ns period)
	always
		# 5 clk = !clk;

	reg [7:0] test_data = 0;
	reg [7:0] read_data = 0;
	integer i, c, j;
	initial begin
		`setup_vcd(test_spi_slave_simple);

		mosi = 0;
		sclk = 0;
		ss = 1;

		@(negedge clk);

		// send a byte
		ss = 1; // start
		@(negedge clk);

		mosi = 1;
		repeat(8) begin
			@(negedge clk); @(negedge clk); sclk = 1;
			@(negedge clk); @(negedge clk); sclk = 0;
		end
		// on the clock after sclk is risen for the 8th bit a byte is valid
		`assert_eq(valid, 1);
		`assert_eq(data, 'hff);

		@(negedge clk);
		`assert_eq(valid, 0);

		ss = 0; // release
		@(negedge clk);
		`assert_eq(valid, 0);

		@(negedge clk);
		@(negedge clk);
		@(negedge clk);

		// multi-byte
		ss = 1;
		@(negedge clk);

		for (i = 0; i < 4; i = i + 1) begin
			test_data = i;
			for (j = 0; j < 8; j = j + 1) begin
				mosi = test_data[7 - j];
				@(negedge clk); @(negedge clk); sclk = 1;
				read_data = {read_data[6:0], miso};
				@(negedge clk); @(negedge clk); sclk = 0;
			end

			// on the clock after sclk is risen for the 8th bit a byte is valid
			`assert_eq(valid, 1);
			$display("got %h, expected %h", data, test_data[7:0]);
			`assert_eq(data, test_data[7:0]);
			if (i != 0)
				`assert_eq(read_data, i - 1);
		end

		@(negedge clk);
		`assert_eq(valid, 0);

		ss = 0; // release
		@(negedge clk);
		`assert_eq(valid, 0);

		// large multi-byte
		ss = 1;
		@(negedge clk);

		for (i = 0; i < 257; i = i + 1) begin
			test_data = i;
			for (j = 0; j < 8; j = j + 1) begin
				mosi = test_data[7 - j];
				@(negedge clk); @(negedge clk); sclk = 1;
				read_data = {read_data[6:0], miso};
				@(negedge clk); @(negedge clk); sclk = 0;
			end

			// on the clock after sclk is risen for the 8th bit a byte is valid
			`assert_eq(valid, 1);
			$display("got %h, expected %h", data, test_data[7:0]);
			$display("read %h, expected %h", read_data, i - 1);
			`assert_eq(data, test_data[7:0]);
			if (i != 0)
				`assert_eq(read_data, i - 1);

			// interword delay, to introduce some sort of timing error
			for (j = 0; j < 512; j = j + 1) begin
				@(negedge clk);
			end
		end

		@(negedge clk);
		`assert_eq(valid, 0);

		ss = 0; // release

		$finish(0);
	end
endmodule

