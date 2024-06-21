module key_generator_tb();

    logic [23:0] key;
    logic clk;
    logic start;
    logic reset;
    logic finished;
    logic terminated;

    key_generator #(
        .KEY_UPPER(24'h000005),
        .KEY_LOWER(24'h000000)
    ) keyGen(
        .clk(clk),
        .start(start),
        .reset(reset),
        .finished(finished),
        .terminated(terminated),
        .key(key)
    );


    always begin
        #5
        clk = ~clk;
    end


    initial begin
        #50
        start = 1;
        #20 
        start = 0;
        #20
        start = 1;
        #20 
        start = 0;
        #20
        start = 1;
        #20 
        start = 0;
        #20
        start = 1;
        #20 
        start = 0;
        #20
        start = 1;
        #20 
        start = 0;
        #500
        start = 1;
        #50
        start = 0;
        #10
        start = 1;
    end


    initial begin
        reset = 1;
        clk = 0;
        start = 0;
        #16
        reset = 0;
    end

    initial begin
        #12000;
        $finish;
    end


endmodule