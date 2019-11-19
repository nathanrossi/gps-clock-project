
module spi_slave(clk, rst, sclk, ss, mosi, miso, data, valid);
	parameter ss_active = 1;
	input wire clk, rst, sclk, ss;
	input wire mosi;
	output wire miso;

	// Operation
	// ---------
	// SS   ^^^^^|_________________...__________________|^^^
	// CLK  ______|^|_|^|_|^|_|^|_...._|^|_|^|_|^|_|^|______
	// MOSI _____<  ><  ><  ><  ><....<  ><  ><  ><  >______
	// MISO _____<  ><  ><  ><  ><....<  ><  ><  ><  >______
	//
	// MSB first

	reg [7:0] iword = 0;
	reg [7:0] oword = 0;
	reg [2:0] count = 0;

	output wire [7:0] data;
	output reg valid;

	assign data = iword;
	assign miso = oword[7];

	reg [1:0] sclk_buf;
	// need to buffer the input clock, this limits max performance, but
	// provides cleaner clocking and better signal reliablity. Clock must be
	// 4x the system clk.
	always @(posedge clk) begin
		sclk_buf <= {sclk_buf[0], sclk};

		if (rst == 1) begin
			sclk_buf <= 2'b00;
		end
	end

	always @(posedge clk) begin
		valid <= 0;
		if (ss == ss_active && sclk_buf == 2'b01) begin // rising_edge
			// latch mosi
			iword <= {iword[6:0], mosi};

			count <= count + 1; // increment bit
			if (count == 7) begin
				valid <= 1;
			end
		end

		if (rst == 1) begin
			valid <= 0;
			iword <= {8{1'b0}};
			count <= 0;
		end
	end

	always @(posedge clk) begin
		if (ss == ss_active && sclk_buf == 2'b10) begin // falling_edge
			// latch miso
			oword <= {oword[6:0], 1'b0};
			if (count == 0) begin
				oword <= iword;
			end
		end

		if (rst == 1) begin
			oword <= {8{1'b0}};
		end
	end

endmodule

