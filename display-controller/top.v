
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

	reg rst = 0;
	wire [2:0] row;
	wire [4:0] column;
	wire [7:0] cycle;

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

	reg mem_flip = 0, mem_wen = 0;
	reg [23:0] mem_i = 0;
	wire [23:0] mem_o;

	display_memory #(
		.rows(8),
		.columns(32)
	) u_memory (
		.clk(clk),
		.wen(mem_wen),
		.flip(mem_flip),
		.irow(row),
		.icol(column),
		.orow(row),
		.ocol(column),
		.i(mem_i),
		.o(mem_o)
	);

	assign a0 = row[0];
	assign a1 = row[1];
	assign a2 = row[2];

	// set directly from memory
	assign r0 = mem_o[0];
	assign g0 = mem_o[1];
	assign b0 = mem_o[2];
	assign r1 = mem_o[3];
	assign g1 = mem_o[4];
	assign b1 = mem_o[5];

endmodule

