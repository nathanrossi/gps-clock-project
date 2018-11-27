
module display_memory(clk, flip, wen, wrow, wcol, rrow, rcol, wdata, rdata);
	parameter integer segments = 1;
	parameter integer rows = 8;
	parameter integer columns = 32;
	parameter integer width = 24;

	input wire clk, flip, wen;
	input wire [$clog2(rows)-1:0] wrow, rrow;
	input wire [$clog2(columns)-1:0] wcol, rcol;
	input wire [(width * segments) - 1:0] wdata;
	output reg [(width * segments) - 1:0] rdata;

	reg [(width * segments) - 1:0] memory[0:(2 ** ($clog2(rows) + $clog2(columns) + 1)) - 1];
	integer ik;
	initial begin
		for (ik = 0; ik < (2 ** ($clog2(rows) + $clog2(columns) + 1)) - 1; ik = ik + 1) begin
			memory[ik] <= {(width * segments){1'b0}};
		end
	end

	always @(posedge clk) begin
		if (wen) begin
			`ifndef SYNTHESIS
				$display("memory wr @ flip %d, wrow %2d, wcol %2d == %h", !flip, wrow, wcol, wdata);
			`endif
			memory[{!flip, wrow, wcol}] <= wdata;
		end
		`ifndef SYNTHESIS
			$display("memory rd @ flip %d, rrow %2d, rcol %2d == %h", flip, rrow, rcol, memory[{flip, rrow, rcol}]);
		`endif
		rdata <= memory[{flip, rrow, rcol}];
	end

endmodule

