module ksa
    (
        input CLOCK_50,
        input [3:0] KEY,
        input [9:0] SW,
        input [9:0] LEDR,
        input [6:0] HEX0,
        input [6:0] HEX1,
        input [6:0] HEX2,
        input [6:0] HEX3,
        input [6:0] HEX4,
        input [6:0] HEX5
    );

    logic clk;
    assign clk = CLOCK_50;
    assign rst = KEY[3];


endmodule