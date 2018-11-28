`include "helpers.v"

module top_run;
	reg clk = 0;
	reg rst = 1;

	top u_top (
		.clk(clk),
		.rst(rst)
	);

	// 5/5ns clock (10ns period)
	//always
		//# 5 clk = !clk;

	initial begin
		`setup_vcd(top_run);
		repeat(32) begin
			# 5 clk = !clk;
			# 5 clk = !clk;
			rst <= 1;
		end
		rst <= 0;

		repeat(500000) begin
			# 5 clk = !clk;
			# 5 clk = !clk;
		end
		$finish(0);
	end
endmodule

