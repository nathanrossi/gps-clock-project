`include "helpers.v"

module uart_loopback;
	reg clk = 0, rst = 0;
	reg [7:0] idata;
	wire [7:0] odata;
	reg ivalid;
	wire ovalid;
	wire txo;

	uart_tx #(
		.divisor(64)
	) u_uart_tx (
		.clk(clk),
		.rst(rst),
		.txo(txo),
		.data(idata),
		.valid(ivalid)
	);

	uart_rx #(
		.divisor(32)
	) u_uart_rx (
		.clk(clk),
		.rst(rst),
		.rxi(txo),
		.data(odata),
		.valid(ovalid)
	);

	// 5/5ns clock (10ns period)
	always
		# 5 clk = !clk;

	integer c = 0, j = 0;
	initial begin
		`setup_vcd(uart_loopback);

		idata <= 8'h00;
		ivalid <= 0;

		// uarts idles high
		`assert_eq(txo, 1);
		`assert_eq(ovalid, 0);
		rst <= 1;
		@(negedge clk);
		rst <= 0;

		for (j = 0; j < 256; j = j + 1) begin
			// start + data bits
			idata <= j[7:0];
			ivalid <= 1;
			@(negedge clk);
			ivalid <= 0;

			while (ovalid == 0) begin
				@(negedge clk);
				c = c + 1;
			end

			`assert_ge(c, 64);
			`assert_eq(ovalid, 1);
			`assert_eq(odata, j[7:0]);
		end

		$finish(0);
	end
endmodule

