
module display_memory(clk, flip, wen, irow, orow, icol, ocol, i, o);
	parameter rows = 8;
	parameter columns = 32;
	parameter width = 24;

	input wire clk, flip, wen;
	input wire [$clog2(rows)-1:0] irow, orow;
	input wire [$clog2(columns)-1:0] icol, ocol;
	input wire [width-1:0] i;
	output reg [width-1:0] o = 0;

	reg [width-1:0] memory[0:(2 ** ($clog2(rows) + $clog2(columns) + 1)) - 1];
	integer ik;
	initial begin
		for (ik = 0; ik < (2 ** ($clog2(rows) + $clog2(columns) + 1)) - 1; ik = ik + 1) begin
			memory[ik] = ik; // set to high for now, so we get all leds
		end
	end

	reg cycle_w = 0;
	always @(posedge clk) begin
		if (cycle_w == 1) begin
			if (wen ==  1) begin
				memory[{flip, irow, icol}] = i;
			end
			cycle_w = 0;
		end else begin
			o = memory[{!flip, orow, ocol}];
			cycle_w = 1;
		end
	end

endmodule

