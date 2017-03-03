
module top(clk, led0, led1, led2, led3, led4, r0, g0, b0, r1, g1, b1, a0, a1, a2, oe, lat, oclk);
	input clk;
	wire clk;

	output led0, led1, led2, led3, led4;
	assign led0 = 0;
	assign led1 = 0;
	assign led2 = 0;
	assign led3 = 0;
	assign led4 = 1;

	output r0, g0, b0;
	output r1, g1, b1;
	output a0, a1, a2;
	output oe, lat, oclk;
	wire oe, lat, oclk;

	// set all 1 for now
	assign r0 = 1;
	assign g0 = 1;
	assign b0 = 1;
	assign r1 = 1;
	assign g1 = 1;
	assign b1 = 1;

	reg rst = 0;
	reg column;
	reg cycle;
	reg [2:0] row;

	display_driver #(
		.rows(8),
		.columns(32)
	) u_driver (
		.clk(clk),
		.rst(rst),
		.row(row),
		.column(column),
		.cycle(cycle),
		.oe(oe),
		.lat(lat),
		.oclk(oclk)
	);

	assign a0 = row[0];
	assign a1 = row[1];
	assign a2 = row[2];

endmodule

