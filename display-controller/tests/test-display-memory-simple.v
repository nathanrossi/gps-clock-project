
module test_display_memory_simple;
	reg clk;
	reg flip, wen = 0;
	reg [2:0] wrow, rrow = 0;
	reg [4:0] wcol, rcol = 0;
	reg [23:0] wdata = 0;
	wire [23:0] rdata;

	display_memory #(
		.rows(8),
		.columns(32)
	) u_memory (
		.clk(clk),
		.flip(flip),
		.wen(wen),
		.wrow(wrow), .wcol(wcol),
		.rrow(rrow), .rcol(rcol),
		.wdata(wdata),
		.rdata(rdata)
	);

	// 5/5ns clock (10ns period)
	always
		# 5 clk = !clk;

	integer i;
	initial begin
		$dumpfile("test.vcd");
		$dumpvars(0, test_display_memory_simple);

		clk = 0;
		flip = 0;
		wrow = 0;
		rrow = 0;
		wcol = 0;
		rcol = 0;
		wdata = 'h000000;
		wen = 0;

		@(negedge clk);

		// write some data into the first line
		for (i = 0; i < 32; i = i + 1) begin
			wdata = 'hffffff;
			wcol = i;
			rcol = i;
			wen = 1;
			@(negedge clk);
			//helpers.assert_eq(rdata, 'h111111);
		end

		// flip buffers and write some data into the first line
		flip = 1;
		for (i = 0; i < 32; i = i + 1) begin
			wdata = 'h111111;
			wcol = i;
			rcol = i;
			wen = 1;
			@(negedge clk);
			helpers.assert_eq(rdata, 'hffffff);
		end

		// flip buffers and write some data into the first line
		flip = 0;
		for (i = 0; i < 32; i = i + 1) begin
			wdata = 'h101010;
			wcol = i;
			rcol = i;
			wen = 0;
			@(negedge clk);
			helpers.assert_eq(rdata, 'h111111);
		end

		// flip buffers and write some data into the first line
		flip = 1;
		for (i = 0; i < 32; i = i + 1) begin
			wdata = 'h010101;
			wcol = i;
			rcol = i;
			wen = 0;
			@(negedge clk);
			helpers.assert_eq(rdata, 'hffffff);
		end

		$finish(0);
	end
endmodule

