
module top(clk, leds, rgb, a, oe, lat, oclk, spi_sclk, spi_ss, spi_mosi, spi_miso);
	input wire clk;
	reg rst = 0;

	output reg [4:0] leds = 5'b10000;

	// display parameters
	parameter integer segments = 2;
	parameter integer rows = 8;
	parameter integer columns = 32;
	parameter integer bitdepth = 8;

	// internal re-wiring signals/logic
	wire internal_oe;

	// inter-module signals
	wire [$clog2(rows) - 1:0] row;
	wire [$clog2(rows) - 1:0] wrow;
	wire [$clog2(columns) - 1:0] column;
	wire [$clog2(columns) - 1:0] wcol;
	wire [(segments * 3) - 1:0] orgb;
	wire frame_complete;

	reg mem_flip = 0;
	reg ready = 1; // initially ready
	wire wen, loaded;
	wire [(bitdepth * 3 * segments) - 1:0] pixel_load;
	wire [(bitdepth * 3 * segments) - 1:0] pixel_data;

	// outputs to display
	output wire oe, lat, oclk;
	output wire [2:0] a;
	output wire [5:0] rgb;
	assign oe = ~internal_oe;
	assign a = row[2:0];
	assign rgb = orgb;

	// i/o for SPI interface
	input wire spi_sclk, spi_ss, spi_mosi;
	output wire spi_miso;
	wire spi_ss_neg = ~spi_ss;

	// handle memory flip during frame complete
	always @(posedge clk) begin
		if (frame_complete && (loaded || ready == 0)) begin
			mem_flip <= ~mem_flip;
			ready <= 1;
		end else if (loaded) begin
			ready <= 0;
		end
	end

	display_driver #(
		.segments(segments),
		.rows(rows),
		.columns(columns),
		.bitwidth(bitdepth),
		.cyclewidth(8)
	) u_driver (
		.clk(clk),
		.rst(rst),
		.row(row),
		.column(column),
		.frame_complete(frame_complete),
		.pixel(pixel_data),
		.rgb(orgb),
		.oe(internal_oe),
		.lat(lat),
		.oclk(oclk)
	);

	display_memory #(
		.segments(segments),
		.rows(rows),
		.columns(columns),
		.width(bitdepth * 3)
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
		.segments(segments),
		.rows(rows),
		.columns(columns),
		.bitwidth(bitdepth)
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

