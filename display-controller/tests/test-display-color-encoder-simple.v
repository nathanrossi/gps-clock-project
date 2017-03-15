
`include "tests/helpers.v"

module test_display_color_encoder_simple;
	reg clk = 0;
	reg [23:0] pixel;
	reg [7:0] cycle;
	wire [2:0] rgb;

	display_color_encoder u_encoder (
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

		pixel = 'h000000;
		cycle = 'h00;

		@(negedge clk);

		for (i = 0; i < 256; i = i + 1) begin
			pixel = {16'hffff, i[7:0]};
			for (c = 0; c < 256; c = c + 1) begin
				cycle = c;
				@(negedge clk);
				//$display("c = %d, i = %d, rgb %b color = 0x%h", c, i, rgb, pixel);
				`assert_eq(rgb, ({2'b11, (i >= c) && (i != 0)}));
			end
		end

		for (i = 0; i < 256; i = i + 1) begin
			pixel = {8'hff, i[7:0], 8'hff};
			for (c = 0; c < 256; c = c + 1) begin
				cycle = c;
				@(negedge clk);
				//$display("c = %d, i = %d, rgb %b color = 0x%h", c, i, rgb, pixel);
				`assert_eq(rgb, ({1'b1, (i >= c) && (i != 0), 1'b1}));
			end
		end

		for (i = 0; i < 256; i = i + 1) begin
			pixel = {i[7:0], 16'hffff};
			for (c = 0; c < 256; c = c + 1) begin
				cycle = c;
				@(negedge clk);
				//$display("c = %d, i = %d, rgb %b color = 0x%h", c, i, rgb, pixel);
				`assert_eq(rgb, ({(i >= c) && (i != 0), 2'b11}));
			end
		end

		$finish(0);
	end
endmodule

