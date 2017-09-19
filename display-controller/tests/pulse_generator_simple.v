`include "helpers.v"

module pulse_generator_simple;
	reg clk = 0;
	reg rst = 0;
	reg go = 0;
	wire complete;
	wire [$clog2(8) - 1:0] select;

	display_driver_pulse_generator #(
		.bitwidth(8)
	) u_pulse (
		.clk(clk),
		.rst(rst),
		.go(go),
		.complete(complete),
		.select(select)
	);

	// 5/5ns clock (10ns period)
	always
		# 5 clk = !clk;

	initial begin
		integer i = 0, j = 0, k = 0;
		`setup_vcd(pulse_generator_simple);

		rst <= 0;
		go <= 0;

		@(posedge clk);
		@(negedge clk);

		k = 0;
		for (j = 256; j > 1; j = j / 2) begin
			i = 0;
			$display("pulse width halfed to %d", j);
			go <= 1;
			repeat (j) begin
				`assert_eq(complete, 0);
				`assert_eq(select, k);
				@(negedge clk);
				i = i + 1;
			end
			go <= 0;
			`assert_eq(complete, 1);
			`assert_eq(i, j); // took 256 cycles
			k = k + 1;
			if (k > 7)
				k = 0;
			`assert_eq(select, k);
			@(negedge clk);
			`assert_eq(complete, 0);
			`assert_eq(select, k);
		end

		$finish(0);
	end
endmodule
