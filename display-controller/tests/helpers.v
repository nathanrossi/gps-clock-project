
module helpers;
	task assert_eq(input a, b);
		if (a != b) begin
			$display("[%t] assertion: failed, (%d != %d)", $time, a, b);
			$finish(1);
		end
	endtask
endmodule

