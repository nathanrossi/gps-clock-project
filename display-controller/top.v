
module top(clk, led0, led1, led2, led3, led4, r0, g0, b0, r1, g1, b1, a0, a1, a2, oe, lat, oclk);
	input clk;
	wire clk;
	reg [12:0] divider = 0;

	// divide 2
	always @(posedge clk) begin
		divider = divider + 1;
	end
	//wire clk_disp = divider[7];
	wire clk_disp = clk;

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
		.columns(32),
		.cycles(256),
		.row_post(8)
	) u_driver (
		.clk(clk_disp),
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

	reg mem_flip = 0, mem_wen = 0;
	wire [23:0] mem_i;
	wire [23:0] mem_o;

	//assign mem_i = cycle;

	//always @(posedge clk) begin
		//if (cycle == 0 && row == 7 && column == 31) begin
			//mem_flip = !mem_flip;
		//end
	//end

	display_memory #(
		.rows(8),
		.columns(32),
		.width(24)
	) u_memory (
		.clk(clk_disp),
		.wen(mem_wen),
		.flip(mem_flip),
		.wrow(row),
		.wcol(column),
		.rrow(row),
		.rcol(column),
		.wdata(mem_i),
		.rdata(mem_o)
	);

	wire [2:0] rgb;

	display_color_encoder #(
		.cyclewidth(8)
	) u_color_encoder (
		.clk(clk_disp),
		.pixel(mem_o),
		.cycle(cycle),
		.rgb(rgb)
	);

	assign r0 = rgb[0];
	assign g0 = rgb[1];
	assign b0 = rgb[2];
	assign r1 = rgb[0];
	assign g1 = rgb[1];
	assign b1 = rgb[2];

endmodule

