`include "helpers.v"

module display_color_encoder_simple;
	reg clk = 0;
	reg [47:0] pixel;
	reg [47:0] cpixel;

	display_color_encoder #(
		.segments(2),
		.bitwidth(8),
		.cyclewidth(8)
	) u_encoder (
		.clk(clk),
		.pixel(pixel),
		.cpixel(cpixel)
	);

	// 5/5ns clock (10ns period)
	always
		# 5 clk = !clk;

	integer i, c;
	initial begin
		`setup_vcd(display_color_encoder_simple);

		pixel = 'h000000000000;

		// check that the bits propagate on the right cycles
		// use extreme values only, as the color space conversion is too hard
		// to check

		pixel = {24'h000000, 24'hffffff};
		@(negedge clk);
		`assert_eq(cpixel, ({24'h000000, 24'hffffff}));

		pixel = {24'h000000, 24'hffff00};
		@(negedge clk);
		`assert_eq(cpixel, ({24'h000000, 24'hffff00}));

		pixel = {24'h000000, 24'hff00ff};
		@(negedge clk);
		`assert_eq(cpixel, ({24'h000000, 24'hff00ff}));

		pixel = {24'h000000, 24'h00ffff};
		@(negedge clk);
		`assert_eq(cpixel, ({24'h000000, 24'h00ffff}));

		pixel = {24'h000000, 24'h000000};
		@(negedge clk);
		`assert_eq(cpixel, ({24'h000000, 24'h000000}));

		pixel = {24'hffffff, 24'h000000};
		@(negedge clk);
		`assert_eq(cpixel, ({24'hffffff, 24'h000000}));

		$finish(0);
	end
endmodule

