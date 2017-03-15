
module top(clk, led0, led1, led2, led3, led4, r0, g0, b0, r1, g1, b1, a0, a1, a2, oe, lat, oclk, spi_sclk, spi_ss, spi_mosi, spi_miso);
	input clk;
	wire clk;

	// divide 2
	reg [63:0] divider = 'h0000000000000000;
	always @(posedge clk) begin
		divider = divider + 1;
	end
	//wire clk_disp = divider[7];
	//wire clk_disp = divider[3];
	wire clk_disp = clk;

	output led0, led1, led2, led3, led4;
	assign led0 = 0;
	assign led1 = 0;
	assign led2 = 0;
	assign led3 = 0;
	assign led4 = 1;

	// buffer load logic
	//reg started = 0, flip_buffer = 0;
	//wire [7:0] load_data;
	//reg [23:0] load_pixel = 0;
	//reg [2:0] load_row = 7;
	//reg [4:0] load_col = 31; // defaulted to the end so that it wraps on start
	//wire load_valid, load_sot, load_eot;
	//wire flip_safe;
	//integer load_pixel_count = 0;
	//always @(posedge clk_disp) begin
		//if (flip_buffer == 1) begin
			//if (flip_safe == 1) begin
				//mem_flip <= !mem_flip;
				//flip_buffer <= 0;
			//end
		//end else begin
			//if (load_sot == 1 && load_valid == 1) begin
				//// first byte, setup
				//load_pixel <= 0;
				//load_pixel_count <= 0;
				//load_row <= 7;
				//load_col <= 31;
				//mem_wen <= 0;
				//flip_buffer <= 0;
				//started <= 1;
			//end else if(started == 1 && load_eot == 1) begin
				//load_pixel <= 0;
				//load_pixel_count <= 0;
				//load_row <= 7;
				//load_col <= 31;
				//mem_wen <= 0;
				//flip_buffer <= 1;
				//started <= 0;
			//end else if (started == 1 && load_valid == 1) begin
				//load_pixel <= {load_pixel[15:0], load_data};
				//if (load_pixel_count == 1) begin
					//load_pixel_count <= 0;
					//if (load_col >= 31) begin
						//load_col <= 0;
						//if (load_row >= 7) begin
							//load_row <= 0;
						//end else begin
							//load_row <= load_row + 1;
						//end
					//end else begin
						//load_col <= load_col + 1;
					//end
					//mem_wen <= 1;
				//end else begin
					//load_pixel_count <= load_pixel_count + 1;
					//mem_wen <= 0;
				//end
				//flip_buffer <= 0;
			//end else begin
				//mem_wen <= 0;
				//flip_buffer <= 0;
			//end
		//end
	//end

	output r0, g0, b0;
	output r1, g1, b1;
	output a0, a1, a2;
	output oe, lat, oclk;
	wire oe, lat, oclk;

	reg rst = 0;
	wire [2:0] row;
	wire [4:0] column;
	wire [7:0] cycle;

	wire internal_oe;
	assign oe = ~internal_oe;

	display_driver #(
		.rows(8),
		.columns(32),
		.bitdepth(8)
	) u_driver (
		.clk(clk_disp),
		.rst(rst),
		.row(row),
		.column(column),
		.cycle(cycle),
		.safe_flip(flip_safe),
		.oe(internal_oe),
		.lat(lat),
		.oclk(oclk)
	);

	assign a0 = row[0];
	assign a1 = row[1];
	assign a2 = row[2];

	reg mem_flip = 0, mem_wen = 0;
	wire [23:0] mem_o;

	display_memory #(
		.rows(8),
		.columns(32),
		.width(24)
	) u_memory (
		.clk(clk_disp),
		.wen(mem_wen),
		.flip(mem_flip),
		.wrow(load_row),
		.wcol(load_col),
		.rrow(row),
		.rcol(column),
		.wdata(load_pixel),
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

	input wire spi_sclk, spi_ss, spi_mosi;
	output reg spi_miso = 0;
	//input wire spi_sclk, spi_ss, spi_mosi;
	//output wire spi_miso;
	//spi_slave u_spi_slave (
		//.clk(clk_disp),
		//.rst(rst),
		//.sclk(spi_sclk),
		//.ss(spi_ss),
		//.mosi(spi_mosi),
		//.miso(spi_miso),
		//.data(load_data),
		//.valid(load_valid),
		//.sot(load_sot),
		//.eot(load_eot)
	//);

endmodule

