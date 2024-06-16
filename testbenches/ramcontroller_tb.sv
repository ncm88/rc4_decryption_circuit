module ramcontroller_tb();

    logic [7:0] ram_in;
    logic [7:0] ram_out;
    logic [7:0] address;
    logic write_enable;
    logic finished;
    logic clk;
    logic [2:0] mode;
    logic start;
    logic reset;

    logic [23:0] key;
    assign key = {16'b0, 8'b00101000};

    /*
    //dummy memory block for tetsing
    ramcore S(
        .address(address),
        .clock(clk),
        .data(ram_in),
        .wren(write_enable),
        .q(ram_out)
    );
    */
    assign ram_out = 0;


    ramcontroller controller(
        .clk(clk),
        .reset(reset),
        .mode(mode),
        .key(key),
        .start(start),
        .finished(finished),
        .ram_out(ram_out),
        .write_enable(write_enable),
        .ram_in(ram_in),
        .address(address)
    );

    always begin
        #5;
        clk = ~clk;
    end


    initial begin
        mode = 3'b001;
        clk = 0;
        start = 0;
        reset = 1;
        #150
        reset = 0;
        #7
        start = 1;
        #3000
        mode = 3'b010;
        start = 0;
        #60
        start = 1;
        #12000
        start = 0;
    end



    initial begin
        #18000
        $finish;
    end


endmodule