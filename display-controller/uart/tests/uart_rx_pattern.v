`include "helpers.v"

module uart_rx_pattern;
	reg clk = 0, rst = 0;
	reg rxi = 0;
	wire [7:0] data;
	wire valid;

	uart_rx #(
		.divisor(1024)
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

	integer i, c, j;
	initial begin
		`setup_vcd(uart_rx_pattern);

		// uarts idles high
		rxi = 1;
		repeat (10) begin
			@(negedge clk);
		end

		for (j = 0; j < 256; j = j + 1) begin
			// start + data bits
			for (i = 0; i < 9; i = i + 1) begin
				rxi <= (i == 0) ? 1'b0 : j[i - 1];
				repeat (1024) begin
					@(negedge clk);
				end
			end
			// at some point in the above valid was asserted
			`assert_eq(valid, 1);
			`assert_eq(data, j[7:0]);
			@(negedge clk);

			// stop bit
			rxi <= 1;
			repeat (1024) begin
				@(negedge clk);
			end
		end

		$finish(0);
	end
endmodule

