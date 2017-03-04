
module test_display_memory_simple;
	reg clk;
	reg flip, wen = 0;
	reg [2:0] irow, orow = 0;
	reg [4:0] icol, ocol = 0;
	reg [23:0] in = 0;
	wire [23:0] out;

	display_memory #(
		.rows(8),
		.columns(32)
	) u_memory (
		.clk(clk),
		.flip(flip),
		.wen(wen),
		.irow(irow),
		.orow(orow),
		.icol(icol),
		.ocol(ocol),
		.i(in),
		.o(out)
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
		irow = 0;
		orow = 0;
		icol = 0;
		ocol = 0;
		in = 'h000000;
		wen = 0;

		@(posedge clk);
		@(posedge clk);

		// write some data into the first line
		for (i = 0; i < 32; i = i + 1) begin
			in = 'hffffff;
			icol = i;
			ocol = i;
			wen = 1;
			@(posedge clk);
			@(posedge clk);
			//helpers.assert_eq(out, 'h111111);
		end

		// flip buffers and write some data into the first line
		flip = 1;
		for (i = 0; i < 32; i = i + 1) begin
			in = 'h111111;
			icol = i;
			ocol = i;
			wen = 1;
			@(posedge clk);
			@(posedge clk);
			helpers.assert_eq(out, 'hffffff);
		end

		// flip buffers and write some data into the first line
		flip = 0;
		for (i = 0; i < 32; i = i + 1) begin
			in = 'h101010;
			icol = i;
			ocol = i;
			wen = 0;
			@(posedge clk);
			@(posedge clk);
			helpers.assert_eq(out, 'h111111);
		end

		// flip buffers and write some data into the first line
		flip = 1;
		for (i = 0; i < 32; i = i + 1) begin
			in = 'h010101;
			icol = i;
			ocol = i;
			wen = 0;
			@(posedge clk);
			@(posedge clk);
			helpers.assert_eq(out, 'hffffff);
		end

		$finish(0);
	end
endmodule

