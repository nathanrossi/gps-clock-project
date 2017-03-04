
module display_memory(clk, flip, wen, wrow, wcol, rrow, rcol, wdata, rdata);
	parameter rows = 8;
	parameter columns = 32;
	parameter width = 24;
	parameter _addrwidth = (2 ** ($clog2(rows) + $clog2(columns) + 1));

	input wire clk, flip, wen;
	input wire [$clog2(rows)-1:0] wrow, rrow;
	input wire [$clog2(columns)-1:0] wcol, rcol;
	input wire [width-1:0] wdata;
	output reg [width-1:0] rdata;

	reg [width-1:0] memory[0:_addrwidth - 1];
	integer ik;
	initial begin
		$display("_addrwidth = %d", _addrwidth);
		$readmemh("display-data.hex", memory);
		//for (ik = 0; ik < _addrwidth - 1; ik = ik + 1) begin
			//memory[ik] = 'h000f00; // set to high for now, so we get all leds
		//end
	end

	always @(posedge clk) begin
		if (wen)
			memory[{!flip, wrow, wcol}] <= wdata;
		rdata <= memory[{flip, rrow, rcol}];
	end

endmodule

