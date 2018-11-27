module board_icestick(clk, rgb, a, oe, lat, oclk, uart_txo, uart_rxi, leds, debug);
	input wire clk;
	output wire [4:0] leds;
	output wire [7:0] debug;
	// uart
	input wire uart_rxi;
	output wire uart_txo;
	// panel
	output wire oe, lat, oclk;
	output wire [2:0] a;
	output wire [5:0] rgb;

	// PLL clock outputs
	wire pll_locked;
	wire pll_clk;
	pll u_pll (
		.locked(pll_locked),
		.clock_in(clk),
		.clock_out(pll_clk),
	);

	top #(
		.if_uart(1)
	) u_top (
		.clk(pll_clk),

		.leds(leds),
		.debug(debug),

		// led panel
		.rgb(rgb),
		.a(a),
		.oe(oe),
		.lat(lat),
		.oclk(oclk),

		// uart attached to pins
		.uart_rxi(uart_rxi),
		.uart_txo(uart_txo)
	);
endmodule

