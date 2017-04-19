
`define __gen_assert_compare(cmp, acmp, file, line, printtype, a0, a1) do begin \
			if ((a0) acmp (a1)) begin \
				$display("[@%8t %0s:%0d] assertion: 'a0' cmp 'a1' failed, printtype acmp printtype", $time, file, line, (a0), (a1)); \
				$finish_and_return(1); \
			end else begin \
				$display("[@%8t %0s:%0d] assertion: 'a0' cmp 'a1', printtype cmp printtype", $time, file, line, (a0), (a1)); \
			end \
		end while (0)
`define __gen_assert_vect_compare(cmp, acmp, file, line, a0, a1) do begin \
			if ($size(a0) >= 4) begin \
				`__gen_assert_compare(cmp, acmp, `__FILE__, `__LINE__, %h, a0, a1); \
			end else begin \
				`__gen_assert_compare(cmp, acmp, `__FILE__, `__LINE__, %b, a0, a1); \
			end \
		end while (0)

// defines for eq, ne, ge, gt, le, lt for vector and "d*" decimal
`define assert_eq(actual, expected) `__gen_assert_vect_compare(==, !=, `__FILE__, `__LINE__, actual, expected)
`define assert_ne(actual, expected) `__gen_assert_vect_compare(!=, ==, `__FILE__, `__LINE__, actual, expected)
`define assert_ge(actual, expected) `__gen_assert_vect_compare(>=, <, `__FILE__, `__LINE__, actual, expected)
`define assert_gt(actual, expected) `__gen_assert_vect_compare(>, <=, `__FILE__, `__LINE__, actual, expected)
`define assert_le(actual, expected) `__gen_assert_vect_compare(<=, >, `__FILE__, `__LINE__, actual, expected)
`define assert_lt(actual, expected) `__gen_assert_vect_compare(<, >=, `__FILE__, `__LINE__, actual, expected)

`define assert_deq(actual, expected) `__gen_assert_compare(==, !=, `__FILE__, `__LINE__, %0d, actual, expected)
`define assert_dne(actual, expected) `__gen_assert_compare(!=, ==, `__FILE__, `__LINE__, %0d, actual, expected)
`define assert_dge(actual, expected) `__gen_assert_compare(>=, <, `__FILE__, `__LINE__, %0d, actual, expected)
`define assert_dgt(actual, expected) `__gen_assert_compare(>, <=, `__FILE__, `__LINE__, %0d, actual, expected)
`define assert_dle(actual, expected) `__gen_assert_compare(<=, >, `__FILE__, `__LINE__, %0d, actual, expected)
`define assert_dlt(actual, expected) `__gen_assert_compare(<, >=, `__FILE__, `__LINE__, %0d, actual, expected)

