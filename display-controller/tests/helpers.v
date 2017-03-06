
`define assert_eq(a, b) helpers.assert_eq_info(`__FILE__, `__LINE__, a, b)

module helpers;
	task assert_eq(input a, b);
		if (a != b) begin
			$display("[%t] assertion: failed, (%d != %d)", $time, a, b);
			$finish_and_return(1);
		end
	endtask

	task assert_eq_info;
		input [1024:0] file;
		input integer line;
		input a, b;

		if (a != b) begin
			$display("[%8t %0s:%0d] assertion: failed, (%d != %d)", $time, file, line, a, b);
			$finish_and_return(1);
		end
	endtask

endmodule
