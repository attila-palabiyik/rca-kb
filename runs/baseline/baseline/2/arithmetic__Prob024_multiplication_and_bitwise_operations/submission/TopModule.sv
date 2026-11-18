module TopModule(
    input  [7:0]    A,
    output [15:0]   B
    );

//*************code***********//

    wire [10:0] times_five = {1'b0, A, 2'b00} + {3'b000, A};

    assign B = {A, 8'b0} - {5'b0, times_five};
//*************code***********//

endmodule
