
module spi_slave(clk, rst, sclk, ss, mosi, miso, data, valid, sot, eot);
	input wire clk, rst, sclk, ss;
	input wire mosi;
	output reg miso = 0; // not used.

	// Operation
	// ---------
	// Start of transfer resets address, each byte represents a byte of the
	// colorspace. For 24bit color, 3 bytes. Bytes must be written for each
	// pixel, once ss it pulled high at the end of a word the frame is flipped
	// to the display.
	//
	// SS   ^^^^^|_________________...__________________|^^^
	// CLK  ______|^|_|^|_|^|_|^|_...._|^|_|^|_|^|_|^|______
	// MOSI______<  ><  ><  ><  ><....<  ><  ><  ><  >______

	reg [7:0] word = 0;
	reg [2:0] count = 0;
	reg first = 0;
	reg lastsclk = 0;

	output wire [7:0] data;
	assign data = word;
	output reg sot, eot, valid;

	always @(posedge clk) begin
		if (rst == 1) begin
			lastsclk = 0;
			word <= 0;
			count <= 0;
			first <= 0;
			sot <= 0;
			eot <= 0;
		end else begin
			if (ss == 0) begin
				lastsclk <= sclk;
				if (lastsclk == 0 && sclk == 1) begin
					word <= {word[6:0], mosi};
					count <= count + 1;
					if (count == 7) begin
						// 8 bit word recieved.
						valid <= 1; // data is valid for the next tick
						sot <= first;
						first <= 0;
					end else begin
						valid <= 0; // data is no longer valid
					end
				end else begin
					valid <= 0; // data is no longer valid
				end
				eot <= 0;
			end else begin
				// end of transmission
				lastsclk = 0;
				first <= 1;
				eot <= 1;
				sot <= 0;
				valid <= 0;
				word <= 0;
			end
		end
	end
endmodule

