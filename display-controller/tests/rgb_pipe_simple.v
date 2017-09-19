`include "helpers.v"

module rgb_pipe_simple;
	reg clk = 0;
	reg integer select = 0;
	reg go = 0;
	reg [(8 * 3) - 1:0] pixel = {8 * 3{1'b0}};
	wire [2:0] rgb;

	display_driver_rgb_pipe #(
		.pipe_length(2),
		.segments(1),
		.bitwidth(8)
	) u_pipe (
		.clk(clk),
		.rst(rst),
		.go(go),
		.select(select[$clog2(8) - 1:0]),
		.pixel(pixel),
		.rgb(rgb)
	);

	// 5/5ns clock (10ns period)
	always
		# 5 clk = !clk;

	initial begin
		integer i = 0;
		`setup_vcd(rgb_pipe_simple);

		select <= 0;
		go <= 0;
		pixel <= 24'h000000;

		@(posedge clk);
		@(negedge clk);

		// test simple single channel bit passing through pipe
		pixel <= 24'h0000ff;
		go <= 1;

		// pipe should be empty/reset on first cycle
		@(negedge clk);
		`assert_eq(rgb, 3'b000);
		@(negedge clk);
		// should have input value on second
		`assert_eq(rgb, 3'b001);

		// test inline changes
		pixel <= 24'h0000f0;
		@(negedge clk);
		`assert_eq(rgb, 3'b001);
		pixel <= 24'h0000ff;
		@(negedge clk);
		`assert_eq(rgb, 3'b000);
		@(negedge clk);
		`assert_eq(rgb, 3'b001);

		// test stop/go
		pixel <= 24'h0000f0;
		go <= 0;
		@(negedge clk);
		`assert_eq(rgb, 3'b001);
		@(negedge clk);
		`assert_eq(rgb, 3'b001);
		@(negedge clk);
		`assert_eq(rgb, 3'b001);
		go <= 1;
		@(negedge clk);
		`assert_eq(rgb, 3'b001);
		@(negedge clk);
		`assert_eq(rgb, 3'b000);

		// test bit select patterns
		for (i = 0; i < (8 * 2); i = i + 1) begin
			select <= i / 2;
			pixel <= {16'h0000, {8{(i % 2) == 1}}};
			@(negedge clk);
			@(negedge clk);
			`assert_eq(rgb, ({2'b00, (i % 2) == 1}));
		end

		$finish(0);
	end
endmodule

