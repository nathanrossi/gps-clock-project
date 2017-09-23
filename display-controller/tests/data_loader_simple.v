`include "helpers.v"

module data_loader_simple;
	reg clk = 0, rst = 0;
	reg [7:0] idata;
	reg ivalid;
	wire [2:0] row;
	wire [4:0] column;
	wire [23:0] pixel;
	wire wen;
	reg ready = 0;
	wire loaded;

	data_loader #(
		.segments(1),
		.rows(8),
		.columns(32),
		.bitwidth(8)
	) u_loader (
		.clk(clk),
		.rst(rst),
		.idata(idata),
		.ivalid(ivalid),
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

	initial begin
		integer i, j, z, x, y;

		`setup_vcd(data_loader_simple);

		idata <= 8'h00;
		ivalid <= 0;

		clk = 0; rst = 1;
		ready <= 0;
		@(negedge clk);
		rst = 0;
		ready <= 1;
		@(negedge clk);

		// load row 0 with some data
		idata <= 8'hf0; // row 0
		ivalid <= 1;
		`assert_eq(wen, 0);
		@(negedge clk);
		for (i = 0; i < 32; i = i + 1) begin
			idata <= 8'hff;
			if (i == 0) // wen will be 1 after the first column is loaded
				`assert_eq(wen, 0);
			@(negedge clk);
			idata <= 8'hff;
			`assert_eq(wen, 0);
			@(negedge clk);
			idata <= i[7:0];
			`assert_eq(wen, 0);
			@(negedge clk); // load one pixel of data

			// expect that the pixel is written to the memory
			`assert_eq(wen, 1);
			`assert_eq(pixel, ({16'hffff, i[7:0]}));
			`assert_eq(row, 0);
			`assert_eq(column, i);
		end
		ivalid <= 0;
		@(negedge clk);

		// full load of 8 rows and 32 columns, with varied pixel data
		for (j = 0; j < 8; j = j + 1) begin
			$display("load content into row %d", j);
			idata <= {4'hf, j[3:0]};
			ivalid <= 1;
			if (j == 0) // wen will be 1 after the first row is loaded
				`assert_eq(wen, 0);
			@(negedge clk);
			for (i = 0; i < 32; i = i + 1) begin
				$display("pixel data row %d, col %d", j, i);
				idata <= j[7:0];
				if (i == 0) // wen will be 1 after the first column is loaded
					`assert_eq(wen, 0);
				@(negedge clk);
				idata <= 8'hed;
				`assert_eq(wen, 0);
				@(negedge clk);
				idata <= i[7:0];
				`assert_eq(wen, 0);
				@(negedge clk); // load one pixel of data

				`assert_eq(wen, 1);
				`assert_eq(pixel, ({j[7:0], 8'hed, i[7:0]}));
				`assert_eq(row, j);
				`assert_eq(column, i);
			end
		end
		ivalid <= 0;
		@(negedge clk);

		// frame complete/flip
		ivalid <= 1;
		idata <= 8'h10;
		@(negedge clk);
		`assert_eq(loaded, 1);
		ivalid <= 0;
		@(negedge clk);
		`assert_eq(loaded, 0);

		// non-ready load
		ready <= 0;
		idata <= 8'hf0; // row 0
		ivalid <= 1;
		`assert_eq(wen, 0);
		@(negedge clk);
		for (i = 0; i < 32; i = i + 1) begin
			idata <= 8'hff;
			`assert_eq(wen, 0);
			@(negedge clk);
			idata <= 8'hff;
			`assert_eq(wen, 0);
			@(negedge clk);
			idata <= i[7:0];
			`assert_eq(wen, 0);
			@(negedge clk); // load one pixel of data

			// expect that the pixel is written to the memory
			`assert_eq(wen, 0);
			`assert_eq(pixel, ({16'hffff, i[7:0]}));
			`assert_eq(row, 0);
			`assert_eq(column, i);
		end
		ivalid <= 0;
		@(negedge clk);

		// test non-ready flip
		ivalid <= 1;
		idata <= 8'h10;
		@(negedge clk);
		`assert_eq(loaded, 0);
		ivalid <= 0;
		@(negedge clk);
		`assert_eq(loaded, 0);

		// test ready after non-ready
		ready <= 1;
		idata <= 8'hf0; // row 0
		ivalid <= 1;
		`assert_eq(wen, 0);
		@(negedge clk);
		for (i = 0; i < 32; i = i + 1) begin
			idata <= 8'hff;
			if (i == 0)
				`assert_eq(wen, 0);
			@(negedge clk);
			idata <= 8'hff;
			`assert_eq(wen, 0);
			@(negedge clk);
			idata <= i[7:0];
			`assert_eq(wen, 0);
			@(negedge clk); // load one pixel of data

			// expect that the pixel is written to the memory
			`assert_eq(wen, 1);
			`assert_eq(pixel, ({16'hffff, i[7:0]}));
			`assert_eq(row, 0);
			`assert_eq(column, i);
		end
		ivalid <= 0;
		@(negedge clk);

		// brute force test each colour channel
		ready <= 1;
		for (y = 0; y < 3; y = y + 1) begin
			for (z = 0; z < 256; z = z + 1) begin
				if (z == 0 && y == 0)
					`assert_eq(loaded, 0); // loaded will be 0 only for the first frame
				for (j = 0; j < 8; j = j + 1) begin
					ivalid <= 1;
					idata <= {4'hf, j[3:0]};
					if (j == 0)
						`assert_eq(wen, 0);
					@(negedge clk);
					`assert_eq(loaded, 0);
					for (i = 0; i < 32; i = i + 1) begin
						idata <= (y == 0) ? z[7:0] : 8'h00;
						if (i == 0)
							`assert_eq(wen, 0);
						`assert_eq(loaded, 0);
						@(negedge clk);
						idata <= (y == 1) ? z[7:0] : 8'h00;
						`assert_eq(wen, 0);
						`assert_eq(loaded, 0);
						@(negedge clk);
						idata <= (y == 2) ? z[7:0] : 8'h00;
						`assert_eq(wen, 0);
						`assert_eq(loaded, 0);
						@(negedge clk); // load one pixel of data

						$display("Writing colour %1d/%3d to row %2d[%2d], col %2d[%2d]. pixel = %h", y, z, row, j, column, i, pixel);
						`assert_eq(wen, 1);
						`assert_eq(pixel, ({
							(y == 0) ? z[7:0] : 8'h00,
							(y == 1) ? z[7:0] : 8'h00,
							(y == 2) ? z[7:0] : 8'h00
							}));
						`assert_eq(row, j);
						`assert_eq(column, i);
						`assert_eq(loaded, 0);
					end
				end
				// flip the frame
				idata <= 8'h10;
				@(negedge clk);
				`assert_eq(loaded, 1);
			end
		end
		ivalid <= 0;
		@(negedge clk);

		$finish(0);
	end
endmodule

