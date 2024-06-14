module ramcontroller_tb();

    logic [7:0] ram_in;
    logic [7:0] address;
    logic wrenbus;
    logic finished_bus;
    logic clk;
    logic [2:0] mode;
    logic start;

    assign mode = 3'b001;

    ramcontroller controller(
        .clk(clk),
        .mode(mode),
        .start(start),
        .finished_bus(finished_bus),
        .wrenbus(wrenbus),
        .ram_in(ram_in),
        .address(address)
    );

    always begin
        #5;
        clk = ~clk;
    end


    initial begin
        clk = 0;
        start = 0;
        #150
        start = 1;
        #1700
        start = 0;
        #200
        start = 1;
        #1000
        start = 0;
        #10
        start = 1;
    end



    initial begin
        #8000
        $finish;
    end


endmodule