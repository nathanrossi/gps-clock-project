
module test_top;
	reg clk = 0;

	top u_top (
		.clk(clk)
	);

	// 5/5ns clock (10ns period)
	//always
		//# 5 clk = !clk;

	integer i = 0;
	initial begin
		`setup_vcd(test_top);
		repeat(500000) begin
			# 5 clk = !clk;
			# 5 clk = !clk;
			i = i + 1;
		end
		$finish(0);
	end
endmodule

