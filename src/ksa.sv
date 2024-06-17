module ksa
    (
        input CLOCK_50,
        input [3:0] KEY,
        input [9:0] SW,
        output [9:0] LEDR,
        input [6:0] HEX0,
        input [6:0] HEX1,
        input [6:0] HEX2,
        input [6:0] HEX3,
        input [6:0] HEX4,
        input [6:0] HEX5
    );

    logic clk, start, reset, finished;
    logic start_sig;
    assign clk = CLOCK_50;
    assign reset = SW[0]; //keys are active low
    assign start = SW[1];
    assign LEDR[0] = finished;

    logic [7:0] ram_in;
    logic [7:0] ram_out;
    logic [7:0] address;
    logic write_enable;

    logic [2:0] state;
    logic [1:0] fTap;
    logic [23:0] key;
    assign key = {10'b0, SW[9:2], 2'b00};

    trap_edge start_trapper(
        .clk(clk),
        .in(start),
        .out(start_sig)
    );
    


    arcfour RC(
        .clk(clk),
        .reset(reset),
        .key(key),
        .start_sig(start_sig),
        .arcfour_finished(finished),
        .ram_out(ram_out),
        .write_enable(write_enable),
        .ram_in(ram_in),
        .address(address),
        .state_tap(state),
        .fTap(fTap)
    );



    //read enable is by default high
    ramcore S (
        .address(address),
        .clock(clk),
        .data(ram_in),
        .wren(write_enable),
        .q(ram_out)
    );


endmodule