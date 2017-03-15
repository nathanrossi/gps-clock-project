
module test_spi_slave_simple;
	reg clk = 0, sclk = 0, rst = 0, ss = 1;
	reg mosi = 0;
	wire miso;
	wire [7:0] data;
	wire valid, sot, eot;

	spi_slave u_spi_slave (
		.clk(clk),
		.rst(rst),
		.sclk(sclk),
		.ss(ss),
		.mosi(mosi),
		.miso(miso),
		.data(data),
		.valid(valid),
		.sot(sot),
		.eot(eot)
	);

	// 5/5ns clock (10ns period)
	always
		# 5 clk = !clk;

	reg [7:0] test_data = 0;
	integer i, c, j;
	initial begin
		$dumpfile({"obj/", `__FILE__, ".vcd"});
		$dumpvars(0, test_spi_slave_simple);

		mosi = 0;
		sclk = 0;
		ss = 1;

		@(negedge clk);

		// send a byte
		ss = 0; // start
		@(negedge clk);

		mosi = 1;
		repeat(8) begin
			@(negedge clk);
			sclk = 1;
			@(negedge clk);
			sclk = 0;
		end
		// on the clock after sclk is risen for the 8th bit a byte is valid
		helpers.assert_eq(valid, 1);
		helpers.assert_eq(data, 'hff);
		helpers.assert_eq(sot, 1);

		@(negedge clk);
		helpers.assert_eq(valid, 0);

		ss = 1; // release
		@(negedge clk);
		helpers.assert_eq(valid, 0);
		helpers.assert_eq(sot, 0);
		helpers.assert_eq(eot, 1);

		// multi-byte
		ss = 0;
		@(negedge clk);

		for (i = 0; i < 4; i = i + 1) begin
			test_data = i;
			for (j = 0; j < 8; j = j + 1) begin
				mosi = test_data[7-j];
				@(negedge clk);
				sclk = 1;
				@(negedge clk);
				sclk = 0;
			end
			// on the clock after sclk is risen for the 8th bit a byte is valid
			helpers.assert_eq(valid, 1);
			$display("got %h, expected %h", data, test_data[7:0]);
			helpers.assert_eq(data, test_data[7:0]);
			helpers.assert_eq(sot, (i == 0));
		end

		@(negedge clk);
		helpers.assert_eq(valid, 0);

		ss = 1; // release
		@(negedge clk);
		helpers.assert_eq(valid, 0);
		helpers.assert_eq(sot, 0);
		helpers.assert_eq(eot, 1);

		$finish(0);
	end
endmodule

