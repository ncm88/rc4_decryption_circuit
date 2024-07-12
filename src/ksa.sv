`default_nettype none
module ksa
    #(
        parameter NUM_CORES = 90,  
        parameter LOG_NUM_CORES = 8,
        parameter MESSAGE_LENGTH = 32,
        parameter MESSAGE_LOG_LENGTH = 5,
        parameter KEY_LENGTH = 3,    //Counts number of bytes in key
        parameter RAM_WIDTH = 8,
        parameter RAM_LENGTH = 8,
        parameter KEY_MAX = 28'hfffffff
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
    assign switchKey = {14'b0, SW[9:0]};     //24'h3fffff;
    

    key_toggle toggler(
        .in(KEY[2]),
        .clk(clk),
        .reset(reset_sig),
        .out(keySel)
    );
    
    edge_detector reset_detector(
        .clk(clk),
        .in(reset),
        .out(reset_sig)
    );

    logic start_sig;
    edge_detector start_detector(
        .clk(clk),
        .in(start),
        .out(start_sig)
    );


    logic start_bit, reset_bit, finish_bit, success_bit;
    typedef enum logic[5:0]{
        FAIL_OR_IDLE = 6'b00_0100,
        RUNNING = 6'b01_0001,     //clear retrieval may be causing some issues
        SUCCESS = 6'b10_1100,
        RESET = 6'b11_0010
    }state_t;
    state_t state, next_state;

    assign start_bit = state[0];
    assign reset_bit = state[1];
    assign finish_bit = state[2];
    assign success_bit = state[3];



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

    logic [NUM_CORES-1:0] success_bus, registered_success_bus, term_bus;
    logic [LOG_NUM_CORES-1:0] core_ptr, mapped_core_ptr;
    logic [NUM_CORES-1:0][KEY_LENGTH*RAM_WIDTH-1:0] keys, curr_keys;

    
    logic success_sig, term_sig, kill_sig;        //Register these next
    assign success_sig = |success_bus;
    assign term_sig = &term_bus;
    assign kill_sig = success_sig || term_sig;


    bus_lock
    #(
        .BUS_WIDTH(NUM_CORES)
    ) success_lock (
        .clk(clk),
        .reset(reset_bit),
        .enable(start_bit),
        .inBus(success_bus),
        .outBus(registered_success_bus)
    );


    bus_lock
    #(
        .BUS_WIDTH(NUM_CORES*KEY_LENGTH*RAM_WIDTH)
    ) key_lock (
        .clk(clk),
        .reset(reset_bit),
        .enable(start_bit),
        .inBus(keys),
        .outBus(curr_keys)
    );


    first_bit_detector 
    #(
        .BUS_WIDTH(NUM_CORES),
        .LOG_BUS_WIDTH(LOG_NUM_CORES)
    ) core_detector (
        .bus(registered_success_bus), 
        .addr(mapped_core_ptr)
    );


    logic finish_sig_out, success_sig_out;
    always_ff @(posedge clk) begin
        if(reset_bit) core_ptr <= 0;
        else core_ptr <= mapped_core_ptr;
        finish_sig_out <= finish_bit;
        success_sig_out <= success_bit;
    end

    logic [KEY_LENGTH*RAM_WIDTH-1:0] curr_key;
    assign curr_key = keys[core_ptr];


    localparam k = (KEY_MAX+1)/NUM_CORES;
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
                .reset(reset_bit),
                .switch_key(switchKey),
                .start(start_bit),
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
                .outKey(keys[i]),
                .terminated(term_bus[i])
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

///////////////////////////////////////////////////////STATE TRANSITION LOGIC////////////////////////////////////////////////////////////////////////////////////////////////


    always_comb begin
        case(state)
            FAIL_OR_IDLE: next_state = start_sig? RUNNING : FAIL_OR_IDLE;
            RUNNING: next_state = kill_sig? (success_sig? SUCCESS : FAIL_OR_IDLE) : RUNNING;
            SUCCESS: next_state = start_sig? RUNNING : SUCCESS;
            RESET: next_state = FAIL_OR_IDLE;
            default: next_state = FAIL_OR_IDLE;
        endcase
    end


    always_ff @(posedge clk) begin
        if(reset_sig) state <= RESET;
        else state <= next_state;
    end



/////////////////////////////////////////////////////////////////////DEBUG///////////////////////////////////////////////////////////////////////////////////////////////

    assign LEDR[0] = keySel;
    assign LEDR[1] = finish_sig_out;
    assign LEDR[2] = success_sig_out;
    assign LEDR[9:3] = core_ptr[7:0];

    SevenSegmentDisplayDecoder decoder (.nIn(curr_key[3:0]), .ssOut(HEX0));
    SevenSegmentDisplayDecoder decoder2 (.nIn(curr_key[7:4]), .ssOut(HEX1));
    SevenSegmentDisplayDecoder decoder3 (.nIn(curr_key[11:8]), .ssOut(HEX2));
    SevenSegmentDisplayDecoder decoder4 (.nIn(curr_key[15:12]), .ssOut(HEX3));
    SevenSegmentDisplayDecoder decoder5 (.nIn(curr_key[19:16]), .ssOut(HEX4));
    SevenSegmentDisplayDecoder decoder6 (.nIn(curr_key[23:20]), .ssOut(HEX5));

endmodule