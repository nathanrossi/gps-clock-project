
`include "tests/helpers.v"

module test_display_color_encoder_simple;
	reg clk = 0;
	reg [47:0] pixel;
	reg [7:0] cycle;
	wire [5:0] rgb;

	display_color_encoder #(
		.segments(2)
	) u_encoder (
		.clk(clk),
		.pixel(pixel),
		.cycle(cycle),
		.rgb(rgb)
	);

	// 5/5ns clock (10ns period)
	always
		# 5 clk = !clk;

	integer i, c;
	initial begin
		$dumpfile({"obj/", `__FILE__, ".vcd"});
		$dumpvars(0, test_display_color_encoder_simple);

		pixel = 'h000000000000;
		cycle = 'h00;

		// check that the bits propagate on the right cycles
		// use extreme values only, as the color space conversion is too hard
		// to check

		pixel = {24'h000000, 24'hffffff};
		for (c = 0; c < 256; c = c + 1) begin
			cycle = c;
			@(negedge clk);
			@(negedge clk);
			`assert_eq(rgb, ({3'b000, 3'b111}));
		end

		pixel = {24'h000000, 24'hffff00};
		for (c = 0; c < 256; c = c + 1) begin
			cycle = c;
			@(negedge clk);
			@(negedge clk);
			`assert_eq(rgb, ({3'b000, 3'b110}));
		end

		pixel = {24'h000000, 24'hff00ff};
		for (c = 0; c < 256; c = c + 1) begin
			cycle = c;
			@(negedge clk);
			@(negedge clk);
			`assert_eq(rgb, ({3'b000, 3'b101}));
		end

		pixel = {24'h000000, 24'h00ffff};
		for (c = 0; c < 256; c = c + 1) begin
			cycle = c;
			@(negedge clk);
			@(negedge clk);
			`assert_eq(rgb, ({3'b000, 3'b011}));
		end

		pixel = {24'h000000, 24'h000000};
		for (c = 0; c < 256; c = c + 1) begin
			cycle = c;
			@(negedge clk);
			@(negedge clk);
			`assert_eq(rgb, ({3'b000, 3'b000}));
		end

		pixel = {24'hffffff, 24'h000000};
		for (c = 0; c < 256; c = c + 1) begin
			cycle = c;
			@(negedge clk);
			@(negedge clk);
			`assert_eq(rgb, ({3'b111, 3'b000}));
		end

		$finish(0);
	end
endmodule

