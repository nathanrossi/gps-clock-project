`include "helpers.v"

module display_memory_simple;
	reg clk = 0;
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

	initial begin
		integer i = 0, j = 0;

		`setup_vcd(display_memory_simple);

		flip <= 0;
		wrow <= 0;
		rrow <= 0;
		wcol <= 0;
		rcol <= 0;
		wdata <= 'h000000;
		wen <= 0;

		@(negedge clk);

		for (j = 0; j < 8; j = j + 1) begin
			// write some data into the first line, check the first line is 0s
			for (i = 0; i < 32; i = i + 1) begin
				flip <= 0;
				wdata <= 'hffffff;
				wcol <= i;
				wrow <= j;
				wen <= 1;
				@(negedge clk);

				//$display("read data @ %d, value = %h", i, rdata);
				`assert_eq(rdata, 24'h000000);

				wen <= 0;
				flip <= 1;
				rcol <= i;
				rrow <= j;
				@(negedge clk);

				//$display("read data @ %d, value = %h", i, rdata);
				`assert_eq(rdata, 24'hffffff);
			end
		end

		$finish(0);

		// flip buffers and write some data into the first line
		flip = 1;
		for (i = 0; i < 32; i = i + 1) begin
			wdata = 'h111111;
			wcol = i;
			rcol = i;
			wen = 1;
			@(negedge clk);
			`assert_eq(rdata, 'hffffff);
		end

		// flip buffers and write some data into the first line
		flip = 0;
		for (i = 0; i < 32; i = i + 1) begin
			wdata = 'h101010;
			wcol = i;
			rcol = i;
			wen = 0;
			@(negedge clk);
			`assert_eq(rdata, 'h111111);
		end

		// flip buffers and write some data into the first line
		flip = 1;
		for (i = 0; i < 32; i = i + 1) begin
			wdata = 'h010101;
			wcol = i;
			rcol = i;
			wen = 0;
			@(negedge clk);
			`assert_eq(rdata, 'hffffff);
		end

		$finish(0);
	end
endmodule

