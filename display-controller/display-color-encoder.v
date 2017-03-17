
module display_color_encoder(clk, pixel, cpixel);
	parameter segments = 1;
	parameter cyclewidth = 8;
	parameter bitwidth = 8;

	input wire clk;
	input wire [((bitwidth * 3) * segments) - 1:0] pixel;
	output reg [((bitwidth * 3) * segments) - 1:0] cpixel = 0;

	// Gamma Correction lookup table
	//
	// This is a pre-generated table of R.G,B values that correspond to pulse
	// width cycles that are corrected for gamma based on the gamma_correction
	// parameter.
	//
	// This is used to represent decoded luminance properly.
	//
	// This does not provide per-channel full channel look up (aka is not a 3D
	// colorspace LUT). But does allow for per channel individual remapping,
	// this is because in order to decode faster all three channels are
	// decoded via individual LUTs.
	//
	// For now the pre-loading LUT info is based on all channels having the
	// same gamma correction.
	//

	genvar g;
	integer i;
	generate
		for (g = 0; g < segments * 3; g = g + 1) begin
			reg [cyclewidth - 1:0] gamma_lookup_data [0:(2 ** bitwidth) - 1];
			initial begin
				$readmemh("obj/gamma-lookup-table.hex", gamma_lookup_data);
				`ifndef SYNTHESIS
				if (g == 0) begin
					// Display the values, for manual checking
					for (i = 0; i < (2 ** bitwidth); i = i + 1) begin
						$display("[GAMMA LUT] in %d => %b [%d]", i, gamma_lookup_data[i], gamma_lookup_data[i]);
					end
				end
				`endif
			end

			integer z;
			always @(posedge clk) begin
				z = g * bitwidth;
				cpixel[z +:bitwidth] <= gamma_lookup_data[pixel[z +:bitwidth]];
			end
		end
	endgenerate

endmodule

