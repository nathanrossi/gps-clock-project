
module top(clk, rst, rgb, a, oe, lat, oclk, uart_txo, uart_rxi, spi_sclk, spi_ss, spi_mosi, spi_miso, leds, debug);
	input wire clk;
	input wire rst;

	output reg [7:0] debug = 0;
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
	reg frame_flipped = 0;
	reg ready = 1; // initially ready
	wire wen, loaded;
	wire [(bitdepth * 3 * segments) - 1:0] pixel_load;
	wire [(bitdepth * 3 * segments) - 1:0] pixel_data;

	// outputs to display
	output wire oe, lat, oclk;
	output wire [2:0] a; // TODO: always handle 4 bit addressing
	output wire [5:0] rgb;
	assign oe = ~internal_oe;
	assign a = row[2:0];
	assign rgb = orgb;

	// handle memory flip during frame complete
	always @(posedge clk) begin
		frame_flipped <= 0;
		if (frame_complete && (ready == 0)) begin
			// was not ready, thus must have a frame loaded, so lets flip it
			// in. And because we have flipped it in, we are ready to accept
			// another frame to be loaded
			mem_flip <= ~mem_flip;
			ready <= 1;
			frame_flipped <= 1;
		end else if (ready && loaded) begin
			// latch the loaded stated and become non-ready
			ready <= 0;
		end
	end

	display_driver #(
		.segments(segments),
		.rows(rows),
		.columns(columns),
		.bitwidth(bitdepth)
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

	// loader signals from spi/uart recv
	wire [7:0] loader_data;
	wire loader_valid;

	data_loader #(
		.segments(segments),
		.rows(rows),
		.columns(columns),
		.bitwidth(bitdepth)
	) u_loader (
		.clk(clk),
		.rst(rst),
		.idata(loader_data),
		.ivalid(loader_valid),
		.wdata(pixel_load),
		.wen(wen),
		.wrow(wrow),
		.wcol(wcol),
		.ready(ready),
		.loaded(loaded)
	);

	// i/o for SPI interface
	input wire spi_sclk, spi_ss, spi_mosi;
	output wire spi_miso;

	// i/o for UART interface
	input wire uart_rxi;
	output wire uart_txo;

	parameter integer if_uart = 0;
	parameter integer if_spi = 0;

	generate
		if (if_uart == 1) begin
			uart_rx #(
				.bitwidth(bitdepth),
				.divisor((`TARGET_FREQ * 1000000) / 115200 / 2)
			) u_uart_rx (
				.clk(clk),
				.rst(rst),
				.rxi(uart_rxi),
				.data(loader_data),
				.valid(loader_valid)
			);

			uart_tx #(
				.bitwidth(bitdepth),
				.divisor((`TARGET_FREQ * 1000000) / 115200)
			) u_uart_tx (
				.clk(clk),
				.rst(rst),
				.txo(uart_txo),
				.data('he0),
				.valid(frame_flipped)
			);
		end else if (if_spi == 1) begin
			spi_slave #(
				.ss_active(0)
			) u_spi_slave (
				.clk(clk),
				.rst(rst),
				.sclk(spi_sclk),
				.ss(spi_ss),
				.mosi(spi_mosi),
				.miso(spi_miso),
				.data(loader_data),
				.valid(loader_valid)
			);
		end
	endgenerate
endmodule

