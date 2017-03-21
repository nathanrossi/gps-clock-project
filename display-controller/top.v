
module top(clk, led0, led1, led2, led3, led4, r0, g0, b0, r1, g1, b1, a0, a1, a2, oe, lat, oclk, spi_sclk, spi_ss, spi_mosi, spi_miso);
	input wire clk;
	reg rst = 0;

	output led0, led1, led2, led3, led4;
	assign led0 = 0;
	assign led1 = 0;
	assign led2 = 0;
	assign led3 = 0;
	assign led4 = 1;

	reg mem_flip = 0;
	wire [23:0] pixel_data;

	reg ready = 1; // initially ready
	wire wen, loaded;
	wire [23:0] pixel_load;
	wire [2:0] wrow;
	wire [4:0] wcol;

	// handle memory flip during frame complete
	always @(posedge clk) begin
		if (frame_complete && (loaded || ready == 0)) begin
			mem_flip <= ~mem_flip;
			ready <= 1;
		end else if (loaded) begin
			ready <= 0;
		end
	end

	output r0, g0, b0;
	output r1, g1, b1;
	output a0, a1, a2;

	input wire spi_sclk, spi_ss, spi_mosi;
	output wire spi_miso;
	wire spi_ss_neg = ~spi_ss;

	output wire oe, lat, oclk;
	wire internal_oe;
	assign oe = ~internal_oe;

	assign a0 = row[0];
	assign a1 = row[1];
	assign a2 = row[2];

	assign r0 = rgb[0];
	assign g0 = rgb[1];
	assign b0 = rgb[2];
	assign r1 = rgb[0];
	assign g1 = rgb[1];
	assign b1 = rgb[2];

	wire [2:0] row;
	wire [4:0] column;
	wire [2:0] rgb;

	display_driver #(
		.segments(1),
		.rows(8),
		.columns(32),
		.bitwidth(8)
	) u_driver (
		.clk(clk),
		.rst(rst),
		.row(row),
		.column(column),
		.frame_complete(frame_complete),
		.pixel(pixel_data),
		.rgb(rgb),
		.oe(internal_oe),
		.lat(lat),
		.oclk(oclk)
	);

	display_memory #(
		.rows(8),
		.columns(32),
		.width(24)
	) u_memory (
		.clk(clk),
		.flip(mem_flip),
		.wen(wen),
		.wrow(wrow),
		.wcol(wcol),
		.wdata(pixel_load),
		.rrow(row),
		.rcol(column),
		.rdata(pixel_data)
	);

	spi_controller #(
		.segments(1),
		.rows(8),
		.columns(32),
		.bitwidth(8)
	) u_loader (
		.clk(clk),
		.rst(rst),
		.sclk(spi_sclk),
		.ss(spi_ss_neg),
		.mosi(spi_mosi),
		.miso(spi_miso),
		.wdata(pixel_load),
		.wen(wen),
		.wrow(wrow),
		.wcol(wcol),
		.ready(ready),
		.loaded(loaded)
	);

endmodule

