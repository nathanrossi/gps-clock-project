module board_up5k(r, g, b, a, clk, lat, oe, spi_sclk, spi_ss, spi_mosi, spi_miso);
	// spi
	input wire spi_sclk, spi_ss, spi_mosi;
	output wire spi_miso;

	wire int_clk;
	// high freq 48MHz internal osc
	SB_HFOSC u_hf_osc (
		.CLKHFPU(1'b1),
		.CLKHFEN(1'b1),
		.CLKHF(int_clk)
	);

	// PLL clock outputs
	wire pll_locked;
	wire pll_clk;
	pll u_pll (
		.locked(pll_locked),
		.clock_in(int_clk),
		.clock_out(pll_clk),
	);

	// wait some time before clearing reset after pll lock
	reg rst;
	reg integer rst_counter;
	always @(posedge pll_clk) begin
		if (pll_locked == 0) begin
			rst_counter <= 0;
			rst <= 1;
		end else begin
			if (rst_counter[5] == 1) begin
				rst <= 0;
			end else begin
				rst <= 1;
				rst_counter <= rst_counter + 1;
			end
		end
	end

	output wire [1:0] r;
	output wire [1:0] g;
	output wire [1:0] b;
	output wire [3:0] a;
	output wire clk;
	output wire lat;
	output wire oe;
	// sink a[3] to gnd unless its used
	assign a[3] = 0'b0;

	top #(
		.if_spi(1)
	) u_top (
		.clk(pll_clk),
		.rst(rst),

		// led panel attached to header_c
		.rgb({r[0], g[0], b[0], r[1], g[1], b[1]}),
		.a(a[2:0]),
		.oclk(clk),
		.lat(lat),
		.oe(oe),

		// spi attached to FT2232H
		.spi_sclk(spi_sclk),
		.spi_ss(spi_ss),
		.spi_mosi(spi_mosi),
		.spi_miso(spi_miso),
	);
endmodule

