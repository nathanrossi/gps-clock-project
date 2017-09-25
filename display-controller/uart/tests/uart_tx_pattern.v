`include "helpers.v"

module uart_tx_pattern;
	reg clk = 0, rst = 0;
	reg [7:0] data;
	reg valid;
	wire txo;

	uart_tx #(
		.divisor(32)
	) u_uart_tx (
		.clk(clk),
		.rst(rst),
		.txo(txo),
		.data(data),
		.valid(valid)
	);

	// 5/5ns clock (10ns period)
	always
		# 5 clk = !clk;

	integer i, c, j;
	initial begin
		`setup_vcd(uart_tx_pattern);

		data <= 8'h00;
		valid <= 0;

		// uarts idles high
		`assert_eq(txo, 1);
		rst <= 1;
		repeat (10) begin
			@(negedge clk);
		end
		rst <= 0;

		for (j = 0; j < 256; j = j + 1) begin
			// start + data bits
			data <= j[7:0];
			valid <= 1;
			@(negedge clk);
			valid <= 0;

			for (i = 0; i < 10; i = i + 1) begin
				repeat (32) begin
					if (i == 0)
						`assert_eq(txo, 0);
					else if (i == 9)
						`assert_eq(txo, 1);
					else
						`assert_eq(txo, data[i - 1]);
					@(negedge clk);
				end
			end
			@(negedge clk);
		end

		$finish(0);
	end
endmodule

