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

    logic clk, rst, write_enable, finished_bus, wrenbus;
    
    assign clk = CLOCK_50;

    logic [7:0] address;
    logic [7:0] ram_in;
    logic [7:0] ram_out;


    ramcontroller controller(
        .clk(clk),
        .mode(3'b001),
        .start(KEY[1]),
        .reset(KEY[0]),
        .finished_bus(finished_bus),
        .wrenbus(wrenbus),
        .ram_in(ram_in),
        .address(address)
    );



    //read enable is by default high
    ramcore S (
        .address(address),
        .clock(clk),
        .data(ram_in),
        .wren(wrenbus),
        .q(ram_out)
    );

endmodule