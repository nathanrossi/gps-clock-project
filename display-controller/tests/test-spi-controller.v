
`include "tests/helpers.v"

module test_spi_controller;
	reg clk = 0, rst = 0;
	reg sclk = 0, ss = 0, mosi = 0;
	wire miso;
	wire [2:0] row;
	wire [4:0] column;
	wire [23:0] pixel;
	wire wen;
	reg ready = 0;
	wire loaded;

	spi_controller #(
		.segments(1),
		.rows(8),
		.columns(32),
		.bitwidth(8)
	) u_controller (
		.clk(clk),
		.rst(rst),
		.sclk(sclk),
		.ss(ss),
		.mosi(mosi),
		.miso(miso),
		.wrow(row),
		.wcol(column),
		.wen(wen),
		.wdata(pixel),
		.ready(ready),
		.loaded(loaded)
	);

	// 5/5ns clock (10ns period)
	always
		# 5 clk = !clk;

	task clkword;
		input [7:0] x;
		integer i;
		begin
			//$display("[SPI] write 0x%h to mosi", x);
			for (i = 0; i < 8; i = i + 1) begin
				mosi <= x[7 - i];
				@(negedge clk); @(negedge clk); sclk <= 1;
				@(negedge clk); @(negedge clk); sclk <= 0;
			end
		end
	endtask

	initial begin
		integer i, j, z, x, y;

		`setup_vcd(test_spi_controller);

		mosi <= 0; sclk <= 0; ss <= 0;
		clk = 0; rst = 1;
		ready <= 0;
		@(negedge clk);
		rst = 0;
		@(negedge clk);

		// load some data into the spi controller
		ready <= 1;
		@(negedge clk);
		ss <= 1; // begin
		@(negedge clk);
		clkword(8'hf0);

		for (i = 0; i < 32; i = i + 1) begin
			clkword(8'hff);
			clkword(8'hff);
			clkword(i[7:0]);

			@(negedge clk); // state should be valid on the clock after the last word is loaded

			`assert_eq(wen, 1);
			`assert_eq(pixel, ({16'hffff, i[7:0]}));
			`assert_eq(row, 0);
			`assert_eq(column, i);
		end
		ss <= 0;

		@(negedge clk);
		@(negedge clk);
		@(negedge clk);
		@(negedge clk);

		ss <= 1; // begin
		@(negedge clk);
		clkword(8'hf1);
		for (i = 0; i < 32; i = i + 1) begin
			clkword(8'h00);
			clkword(8'hed);
			clkword(i[7:0]);

			@(negedge clk); // state should be valid on the clock after the last word is loaded

			`assert_eq(wen, 1);
			`assert_eq(pixel, ({16'h00ed, i[7:0]}));
			`assert_eq(row, 1);
			`assert_eq(column, i);
		end
		ss <= 0;

		@(negedge clk);
		@(negedge clk);
		@(negedge clk);
		@(negedge clk);

		for (j = 2; j < 8; j = j + 1) begin
			ss <= 1; // begin
			clkword({4'hf, j[3:0]});
			for (i = 0; i < 32; i = i + 1) begin
				clkword(j[7:0]);
				clkword(8'hed);
				clkword(i[7:0]);

				@(negedge clk);

				`assert_eq(wen, 1);
				`assert_eq(pixel, ({j[7:0], 8'hed, i[7:0]}));
				`assert_eq(row, j);
				`assert_eq(column, i);
			end
			ss <= 0;
			@(negedge clk);
			@(negedge clk);
			@(negedge clk);
			@(negedge clk);
			@(negedge clk);
		end

		@(negedge clk);
		@(negedge clk);
		@(negedge clk);
		@(negedge clk);

		ss <= 1;
		@(negedge clk);
		clkword(8'h10);
		@(negedge clk);
		ss <= 0;
		@(negedge clk); `assert_eq(loaded, 1);
		@(negedge clk); `assert_eq(loaded, 0);
		ready <= 0;
		@(negedge clk); `assert_eq(loaded, 0);

		// test non-ready load attempt
		repeat (2) begin
			@(negedge clk);
			@(negedge clk);
			`assert_eq(loaded, 0);
			ready <= 0;
			@(negedge clk);
			for (j = 0; j < 8; j = j + 1) begin
				ss <= 1; // begin
				clkword({4'hf, j[3:0]});
				for (i = 0; i < 32; i = i + 1) begin
					clkword(j[7:0]);
					clkword(8'hed);
					clkword(i[7:0]);

					@(negedge clk);

					`assert_eq(wen, 0);
					// wdata, wrow and wcol are not nessecarily valid data
				end
				ss <= 0;
				@(negedge clk);
			end

			ss <= 1;
			@(negedge clk);
			clkword(8'h10);
			@(negedge clk);
			ss <= 0;
			@(negedge clk); `assert_eq(loaded, 0);
			@(negedge clk); `assert_eq(loaded, 0);
		end

		// test ready after non-ready
		@(negedge clk);
		@(negedge clk);
		`assert_eq(loaded, 0);
		ready <= 1;
		@(negedge clk);
		for (j = 0; j < 8; j = j + 1) begin
			ss <= 1; // begin
			clkword({4'hf, j[3:0]});
			for (i = 0; i < 32; i = i + 1) begin
				clkword(j[7:0]);
				clkword(8'hed);
				clkword(i[7:0]);

				@(negedge clk);

				`assert_eq(wen, 1);
				`assert_eq(pixel, ({j[7:0], 8'hed, i[7:0]}));
				`assert_eq(row, j);
				`assert_eq(column, i);
			end
			ss <= 0;
			@(negedge clk);
			@(negedge clk);
			@(negedge clk);
			@(negedge clk);
			@(negedge clk);
		end

		ss <= 1;
		@(negedge clk);
		clkword(8'h10);
		@(negedge clk);
		ss <= 0;
		@(negedge clk); `assert_eq(loaded, 1);
		@(negedge clk); `assert_eq(loaded, 0);

		// test each colour channel
		for (y = 0; y < 3; y = y + 1) begin
			for (z = 0; z < 256; z = z + 1) begin
				@(negedge clk);
				@(negedge clk);
				`assert_eq(loaded, 0);
				ready <= 1;
				@(negedge clk);
				for (j = 0; j < 8; j = j + 1) begin
					ss <= 1; // begin
					clkword({4'hf, j[3:0]});
					for (i = 0; i < 32; i = i + 1) begin
						clkword((y == 0) ? z[7:0] : 8'h00);
						clkword((y == 1) ? z[7:0] : 8'h00);
						clkword((y == 2) ? z[7:0] : 8'h00);

						@(negedge clk);

						$display("Writing colour %1d/%3d to row %2d[%2d], col %2d[%2d]. pixel = %h", y, z, row, j, column, i, pixel);
						`assert_eq(wen, 1);
						`assert_eq(pixel, ({
							(y == 0) ? z[7:0] : 8'h00,
							(y == 1) ? z[7:0] : 8'h00,
							(y == 2) ? z[7:0] : 8'h00
							}));
						`assert_eq(row, j);
						`assert_eq(column, i);
						@(negedge clk);
						`assert_eq(wen, 0);
					end
					ss <= 0;
					@(negedge clk);
					`assert_eq(wen, 0);
					@(negedge clk);
					@(negedge clk);
					@(negedge clk);
					@(negedge clk);
				end

				ss <= 1;
				@(negedge clk);
				clkword(8'h10);
				@(negedge clk);
				ss <= 0;
				@(negedge clk); `assert_eq(loaded, 1);
				@(negedge clk); `assert_eq(loaded, 0);
			end
		end

		# 100
		ss <= 0;

		$finish(0);
	end
endmodule

