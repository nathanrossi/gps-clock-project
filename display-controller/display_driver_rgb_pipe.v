module display_driver_rgb_pipe (clk, rst, go, select, pixel, rgb);
	parameter integer pipe_length = 1; // number of cycles to pipeline
	parameter integer segments = 1;
	parameter integer bitwidth = 8;

	// clock and reset
	input wire clk, rst;

	// input pixel data
	input wire [((bitwidth * 3) * segments) - 1:0] pixel;

	// rgb bits output
	output wire [(3 * segments) - 1:0] rgb;

	// Pipeline the output rgb pixels (depth = mem delay)
	//
	//      oclk
	// <0>   |   |   |   |
	// <1><0>|   |   |   |
	// <3><2>|<1>|   |   |
	//    <4>|<3>|<2>|   |
	//        <5>|<4>|<3>|
	//
	input wire [$clog2(bitwidth) - 1:0] select;
	input wire go;
	reg [(pipe_length * (segments * 3)) - 1:0] rgb_pipe = {pipe_length * (segments * 3){1'b0}};

	genvar g, gg;
	generate
		for (g = 0; g < segments * 3; g = g + 1) begin
			// for each color setup a mux for the pixel bits, this is passed
			// to the rgb pipe
			always @(posedge clk) begin
				if (rst == 1) begin
					rgb_pipe[g] <= 1'b0;
				end else begin
					if (go == 1) begin
						rgb_pipe[g] <= pixel[(g * bitwidth) + select];
					end
				end
			end

			// connect the last pipe node to the output
			assign rgb[g] = rgb_pipe[((segments * 3) * (pipe_length - 1)) + g];

			// push the pipe along
			for (gg = 1; gg < pipe_length; gg = gg + 1) begin
				always @(posedge clk) begin
					if (rst == 1) begin
						rgb_pipe[((segments * 3) * gg) + g] <= 1'b0;
					end else begin
						if (go == 1) begin
							// previous pipe slot
							rgb_pipe[((segments * 3) * gg) + g] <= rgb_pipe[((segments * 3) * (gg - 1)) + g];
						end
					end
				end
			end
		end
	endgenerate
endmodule
