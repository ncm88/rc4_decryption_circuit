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
        .start(SW[0]),
        .mode(SW[3:1]),
        .finished_bus(finished_bus),
        .wrenbus(wrenbus),
        .address(address),
        .ram_in(ram_in),
        .callback(LEDR[1:0]),
        .enCaught(LEDR[4])
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