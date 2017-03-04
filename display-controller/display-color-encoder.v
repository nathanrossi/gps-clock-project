
module display_color_encoder(clk, pixel, cycle, rgb);
	parameter cyclewidth = 8;

	input wire clk;

	input wire [(cyclewidth * 3) - 1:0] pixel;
	input wire [cyclewidth - 1:0] cycle;

	output reg [2:0] rgb = 0;

	// compare pixel rgb values independently to the cycle value, setting high
	// or low on the output rgb bits
	//
	// This is non-synchronized logic, since it is latched externally by the
	// display it self. This avoides needing an additional slot in the
	// pipeline.
	//assign rgb = {
			//(pixel[16 +:cyclewidth] >= cycle && (pixel[16+:cyclewidth] != 0)),
			//(pixel[8 +:cyclewidth] >= cycle && (pixel[8+:cyclewidth] != 0)),
			//(pixel[0 +:cyclewidth] >= cycle && (pixel[0+:cyclewidth] != 0))
		//};

	always @(posedge clk) begin
		rgb <= {
			((pixel[16 +:cyclewidth] >= cycle) && (pixel[16+:cyclewidth] != 0)),
			((pixel[8 +:cyclewidth] >= cycle) && (pixel[8+:cyclewidth] != 0)),
			((pixel[0 +:cyclewidth] >= cycle) && (pixel[0+:cyclewidth] != 0))
		};
	end

endmodule

