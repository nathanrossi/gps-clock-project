
`define __gen_assert_eq(file, line, printtype, a0, a1) do begin \
			if ((a0) != (a1)) begin \
				$display("[@%8t %0s:%0d] assertion: 'a0' == 'a1' failed, printtype != printtype", $time, file, line, (a0), (a1)); \
				$finish_and_return(1); \
			end else begin \
				$display("[@%8t %0s:%0d] assertion: 'a0' == 'a1', printtype == printtype", $time, file, line, (a0), (a1)); \
			end \
		end while (0)

`define assert_eq(actual, expected) do begin \
			if ($size(expected) >= 4) begin \
				`__gen_assert_eq(`__FILE__, `__LINE__, %h, actual, expected); \
			end else begin \
				`__gen_assert_eq(`__FILE__, `__LINE__, %b, actual, expected); \
			end \
		end while (0)

`define assert_deq(actual, expected) `__gen_assert_eq(`__FILE__, `__LINE__, %0d, actual, expected)

