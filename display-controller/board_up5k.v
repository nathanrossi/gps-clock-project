module board_up5k(header_b, spi_sclk, spi_ss, spi_mosi, spi_miso);
	// panel
	output wire [12:0] header_b;
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

	top #(
		.if_spi(1)
	) u_top (
		.clk(pll_clk),

		// led panel attached to header_c
		.rgb(header_b[5:0]),
		.a(header_b[8:6]),
		.oe(header_b[9]),
		.lat(header_b[10]),
		.oclk(header_b[11]),

		// spi attached to FT2232H
		.spi_sclk(spi_sclk),
		.spi_ss(spi_ss),
		.spi_mosi(spi_mosi),
		.spi_miso(spi_miso),
	);
endmodule

