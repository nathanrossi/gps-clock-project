
module display_color_encoder(clk, pixel, cycle, rgb);
	parameter segments = 1;
	parameter cyclewidth = 8;
	parameter bitwidth = 8;
	parameter gamma = 2.2;

	input wire clk;
	input wire [cyclewidth - 1:0] cycle;
	input wire [((bitwidth * 3) * segments) - 1:0] pixel;
	output reg [(3 * segments) - 1:0] rgb = 0;

	reg integer seg_counter = 0;
	reg [cyclewidth - 1:0] corrected_pixel [0:2];

	integer i;
	initial begin
		for (i = 0; i < 3; i = i + 1) begin
			corrected_pixel[i] = 0 ;
		end
	end

	always @(posedge clk) begin
		// connect the channels from corrected to rgb bits
		for (i = 0; i < 3; i = i + 1) begin
			// put the corrected pixel into buffer (to use BRAM)
			corrected_pixel[i] = gamma_lookup[i][pixel[(((bitwidth) * 3) * seg_counter) + (bitwidth * i) +:bitwidth]];

			// push the buffered corrected value to the seg_counter
			rgb[3 * seg_counter + i] <= (corrected_pixel[i] >= cycle) && (corrected_pixel[i] != 0);
		end

		// increment counters
		if (seg_counter + 1 == segments) begin
			seg_counter <= 0;
		end else begin
			seg_counter <= seg_counter + 1;
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
	reg [cyclewidth - 1:0] gamma_lookup [0:2][0:(2 ** bitwidth) - 1];
	real v;
	initial begin
		for (i = 0; i < (2 ** bitwidth); i = i + 1) begin
			v = (($itor(i) / ((2 ** bitwidth) - 1)) ** gamma) * ((2 ** cyclewidth) - 1);
			gamma_lookup[0][i] = v;
			gamma_lookup[1][i] = v;
			gamma_lookup[2][i] = v;
			$display("[GAMMA LUT] in %b => %f %b [%d]", i, v, gamma_lookup[0][i], gamma_lookup[0][i]);
		end
	end

endmodule

