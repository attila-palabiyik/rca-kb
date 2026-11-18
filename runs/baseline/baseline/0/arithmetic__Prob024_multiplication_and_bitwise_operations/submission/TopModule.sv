module TopModule(
    input  [7:0]    A,
    output [15:0]   B
    );

//*************code***********//

    wire [13:0] times_63;

    // 251 = 4 * (64 - 1) - 1.
    assign times_63 = {A, 6'b0} - {6'b0, A};
    assign B = {times_63, 2'b0} - {8'b0, A};
//*************code***********//

endmodule
