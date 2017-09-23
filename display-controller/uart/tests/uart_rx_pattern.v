`include "helpers.v"

module uart_rx_pattern;
	reg clk = 0, rst = 0;
	reg rxi = 0;
	wire [7:0] data;
	wire valid;

	uart_rx #(
		.divisor(32)
	) u_uart_rx (
		.clk(clk),
		.rst(rst),
		.rxi(rxi),
		.data(data),
		.valid(valid)
	);

	// 5/5ns clock (10ns period)
	always
		# 5 clk = !clk;

	integer i, j;
	initial begin
		`setup_vcd(uart_rx_pattern);

		rst <= 1;
		@(negedge clk);
		rst <= 0;

		// uarts idles high
		rxi <= 1;
		repeat (10) begin
			@(negedge clk);
		end

		for (j = 0; j < 256; j = j + 1) begin
			// start + data bits
			for (i = 0; i < 10; i = i + 1) begin
				if (i == 0) // start
					rxi <= 0;
				else if (i == 9) // stop
					rxi <= 1;
				else // data
					rxi <= j[i - 1];

				// once complete the last clock tick the output becomes valid
				repeat (32 * 2) begin
					@(negedge clk);
				end
			end

			// at some point in the above valid was asserted
			`assert_eq(valid, 1);
			`assert_eq(data, j[7:0]);
			@(negedge clk);
		end

		$finish(0);
	end
endmodule
