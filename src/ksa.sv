//TODO: multicore and lint


`default_nettype none
module ksa
    #(
        parameter NUM_CORES = 55,
        parameter MESSAGE_LENGTH = 32,
        parameter MESSAGE_LOG_LENGTH = 5,
        parameter KEY_LENGTH = 3,    //Three byte key assumed by default
        parameter RAM_WIDTH = 8,
        parameter RAM_LENGTH = 8,
        parameter KEY_MAX = 24'hffffffff
    )
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

    logic clk, start, reset;
    logic reset_sig;
    assign clk = CLOCK_50;
    assign reset = KEY[0]; //keys are active low
    assign start = KEY[1];

    logic [7:0] sIn;
    logic [7:0] sOut;
    logic [7:0] sAddr;
    logic sWren;

    logic [7:0] aIn;
    logic [7:0] aAddr;
    logic aWren;

    logic [7:0] kOut;
    logic [4:0] kAddr;
    
    logic [2:0][7:0] switchKey;
    logic keySel;
    
    key_toggle toggler(
        .in(KEY[2]),
        .clk(clk),
        .reset(reset_sig),
        .out(keySel)
    );

    assign switchKey = {14'b0, SW[9:0]};
    
    edge_detector reset_detector(
        .clk(clk),
        .in(reset),
        .out(reset_sig)
    );

    logic clear_start;
    edge_detector start_detector(
        .clk(clk),
        .in(start),
        .out(clear_start)
    );

    logic success, successOut;
    logic finished;

    trap_edge trapper(
        .in(next_killSignal),
        .clk(clk),
        .reset(clear_start), 
        .out(successOut)
    );

    assign LEDR[0] = finished;
    assign LEDR[1] = successOut;
    assign LEDR[2] = keySel;


    ///////////////////////////////////////////////////////////PARALLELIZATION BLOCK///////////////////////////////////////////////////////////////////////////////////////////////////////

    logic [NUM_CORES-1:0] s_wren_bus;                       //Bussin'
    logic [NUM_CORES-1:0][RAM_LENGTH-1:0] s_addr_bus;
    logic [NUM_CORES-1:0][RAM_WIDTH-1:0] s_in_bus;
    logic [NUM_CORES-1:0][RAM_WIDTH-1:0] s_out_bus;

    logic [NUM_CORES-1:0] a_wren_bus;
    logic [NUM_CORES-1:0][MESSAGE_LOG_LENGTH-1:0] a_addr_bus;
    logic [NUM_CORES-1:0][RAM_WIDTH-1:0] a_in_bus;

    logic [NUM_CORES-1:0][MESSAGE_LOG_LENGTH-1:0] k_addr_bus;
    logic [NUM_CORES-1:0][RAM_WIDTH-1:0] k_out_bus;

    logic [NUM_CORES-1:0] success_bus;
    

    logic killSignal, next_killSignal;
    assign next_killSignal = |success_bus;
    always_ff @(posedge clk) begin
        if(reset_sig) killSignal <= 1;
        else killSignal <= next_killSignal;
    end


    localparam k = KEY_MAX/NUM_CORES;

    genvar i;
    generate
        for(i = 0; i < NUM_CORES; i = i + 1) begin : core_generate
            arcfour #(
                .RAM_WIDTH(RAM_WIDTH),
                .RAM_LENGTH(RAM_LENGTH),
                .KEY_LENGTH(KEY_LENGTH),
                .KEY_UPPER(k * (i+1) - 1),
                .KEY_LOWER(k * i),
                .MESSAGE_LENGTH(MESSAGE_LENGTH),
                .MESSAGE_LOG_LENGTH(MESSAGE_LOG_LENGTH)
            ) RC
            (
                .clk(clk),
                .reset(killSignal),
                .switch_key(switchKey),
                .start(start),
                .sIn(s_in_bus[i]),
                .sAddr(s_addr_bus[i]),
                .sWren(s_wren_bus[i]),
                .sOut(s_out_bus[i]),
                .kAddr(k_addr_bus[i]),
                .kOut(k_out_bus[i]),
                .aAddr(a_addr_bus[i]),
                .aIn(a_in_bus[i]),
                .aWren(a_wren_bus[i]),
                .key_select(keySel),
                .success(success_bus[i])
            );


            ramcore S (
                .address(s_addr_bus[i]),
                .clock(clk),
                .data(s_in_bus[i]),
                .wren(s_wren_bus[i]),
                .q(s_out_bus[i])
            );


            ramcore A(
                .address(a_addr_bus[i]),
                .clock(clk),
                .data(a_in_bus[i]),
                .wren(a_wren_bus[i])
            );


            romcore K(
                .address(k_addr_bus[i]),
                .clock(clk),
                .q(k_out_bus[i])
            );

        end
    endgenerate


endmodule