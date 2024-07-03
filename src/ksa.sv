`default_nettype none
module ksa
    #(
        parameter NUM_CORES = 2,  
        parameter LOG_NUM_CORES = 8,
        parameter MESSAGE_LENGTH = 32,
        parameter MESSAGE_LOG_LENGTH = 5,
        parameter KEY_LENGTH = 3,    //Three byte key assumed by default
        parameter RAM_WIDTH = 8,
        parameter RAM_LENGTH = 8,
        parameter KEY_MAX = 24'hffffff
    )
    (
        input CLOCK_50,
        input [3:0] KEY,
        input [9:0] SW,
        output [9:0] LEDR,
        output [6:0] HEX0,
        output [6:0] HEX1,
        output [6:0] HEX2,
        output [6:0] HEX3,
        output [6:0] HEX4,
        output [6:0] HEX5
    );

    logic clk, start, reset, reset_sig;
    assign clk = CLOCK_50;
    assign reset = KEY[0]; //keys are active low
    assign start = KEY[1];


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

    logic successOut;

    trap_edge trapper(
        .in(next_killSignal),
        .clk(clk),
        .reset(clear_start || reset_sig), 
        .out(successOut)
    );

    assign LEDR[0] = successOut;
    assign LEDR[1] = keySel;


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

    logic [NUM_CORES-1:0] success_bus, last_success_bus;
    logic [LOG_NUM_CORES-1:0] core_ptr, next_core_ptr, mapped_core_ptr;
    logic [NUM_CORES-1:0][KEY_LENGTH*RAM_WIDTH-1:0] keys, next_keys;
    logic [NUM_CORES-1:0] fail_bus;
    logic failed, next_failed;


    assign next_failed = &fail_bus;


    logic killSignal, next_killSignal;
    assign next_killSignal = |success_bus;



    first_bit_detector 
    #(
        .BUS_WIDTH(NUM_CORES),
        .LOG_BUS_WIDTH(LOG_NUM_CORES)
    ) core_detector (
        .bus(success_bus), 
        .addr(mapped_core_ptr)
    );


    bus_lock
    #(
        .BUS_WIDTH(LOG_NUM_CORES)
    ) core_lock (
        .clk(clk),
        .reset(reset_sig),
        .trigger(next_killSignal),
        .inBus(mapped_core_ptr),
        .outBus(core_ptr)
    );


    bus_lock
    #(
        .BUS_WIDTH(KEY_LENGTH*RAM_WIDTH)
    ) key_lock (
        .clk(clk),
        .reset(reset_sig),
        .trigger(next_killSignal),
        .inBus(next_keys),
        .outBus(keys)
    );


    bus_lock
    #(
        .BUS_WIDTH(1'b1)
    ) fail_lock (
        .clk(clk),
        .reset(reset_sig),
        .trigger(next_killSignal),
        .inBus(next_failed),
        .outBus(failed)
    );



    logic [KEY_LENGTH*RAM_WIDTH-1:0] curr_key;
    assign curr_key = keys[core_ptr];


    always_ff @(posedge clk) begin
        if(reset_sig) begin
            killSignal <= 1;
        end begin
            killSignal <= next_killSignal;
        end
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
                .start(clear_start),
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
                .succeeded(success_bus[i]),
                .outKey(next_keys[i]),
                .failed(fail_bus[i])
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

//////////////////CORE PTR DISPLAY CODE FOR DEBUG///////////////////////////////////////////////////////////////////////////////////////////////

    assign LEDR[9:2] = core_ptr;

    SevenSegmentDisplayDecoder decoder (.nIn(curr_key[3:0]), .ssOut(HEX0));
    SevenSegmentDisplayDecoder decoder2 (.nIn(curr_key[7:4]), .ssOut(HEX1));
    SevenSegmentDisplayDecoder decoder3 (.nIn(curr_key[11:8]), .ssOut(HEX2));
    SevenSegmentDisplayDecoder decoder4 (.nIn(curr_key[15:12]), .ssOut(HEX3));
    SevenSegmentDisplayDecoder decoder5 (.nIn(curr_key[19:16]), .ssOut(HEX4));
    SevenSegmentDisplayDecoder decoder6 (.nIn(curr_key[23:20]), .ssOut(HEX5));

endmodule