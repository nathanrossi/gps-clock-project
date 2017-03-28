
module display_memory(clk, flip, wen, wrow, wcol, rrow, rcol, wdata, rdata);
	parameter segments = 1;
	parameter rows = 8;
	parameter columns = 32;
	parameter width = 24;
	parameter _addrwidth = (2 ** ($clog2(rows) + $clog2(columns) + 1));

	input wire clk, flip, wen;
	input wire [$clog2(rows)-1:0] wrow, rrow;
	input wire [$clog2(columns)-1:0] wcol, rcol;
	input wire [(width * segments) - 1:0] wdata;
	output reg [(width * segments) - 1:0] rdata = {(width * segments){1'b0}};

	reg [(width * segments) - 1:0] memory[0:_addrwidth - 1];
	integer ik;
	initial begin
		//$readmemh("obj/initial-image-memory.hex", memory);
		for (ik = 0; ik < _addrwidth - 1; ik = ik + 1) begin
			memory[ik] = {(width * segments){1'b0}};
		end
	end

	always @(posedge clk) begin
		if (wen)
			memory[{!flip, wrow, wcol}] <= wdata;
		rdata <= memory[{flip, rrow, rcol}];
	end

endmodule

