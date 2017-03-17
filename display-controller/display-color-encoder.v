
module display_color_encoder(clk, pixel, cpixel);
	parameter segments = 1;
	parameter cyclewidth = 8;
	parameter bitwidth = 8;
	parameter gamma = 2.2;

	input wire clk;
	input wire [((bitwidth * 3) * segments) - 1:0] pixel;
	output reg [((bitwidth * 3) * segments) - 1:0] cpixel = 0;

	integer i, j;
	always @(posedge clk) begin
		// connect the channels from corrected to rgb bits
		for (j = 0; j < segments; j = j + 1) begin
			for (i = 0; i < 3; i = i + 1) begin
				// put the corrected pixel into buffer (to use BRAM)
				cpixel[(((bitwidth) * 3) * j) + (bitwidth * i) +:bitwidth] <=
					gamma_lookup[(3 * j) + i][pixel[(((bitwidth) * 3) * j) + (bitwidth * i) +:bitwidth]];
			end
		end
	end

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
	reg [cyclewidth - 1:0] gamma_lookup [0:(3 * segments) - 1][0:(2 ** bitwidth) - 1];
	reg [cyclewidth - 1:0] gamma_lookup_data [0:(2 ** bitwidth) - 1];
	initial begin
		$readmemh("obj/gamma-lookup-table.hex", gamma_lookup_data);
		for (i = 0; i < (2 ** bitwidth); i = i + 1) begin
			for (j = 0; j < segments * 3; j = j + 1) begin
				gamma_lookup[j][i] = gamma_lookup_data[i];
			end
			// Display the values, for manual checking
			$display("[GAMMA LUT] in %b => %b [%d]", i, gamma_lookup[0][i], gamma_lookup[0][i]);
		end
	end

endmodule

