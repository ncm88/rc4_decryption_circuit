module arcfour
    #(
        parameter RAM_WIDTH,
        parameter RAM_LENGTH,
        parameter NUM_DEVICES = 3,
        parameter KEY_LENGTH,
        parameter MESSAGE_LENGTH,
        parameter MESSAGE_LOG_LENGTH,
        parameter KEY_UPPER,
        parameter KEY_LOWER
    )
    (
        input logic clk,
        input logic reset,
        input logic start,
        input logic key_select,

        input logic [KEY_LENGTH-1:0][RAM_WIDTH-1:0] switch_key,

        /////////////////////////////RAM-S
        output logic sWren,
        input logic [RAM_WIDTH - 1 : 0] sOut,
        output logic [RAM_WIDTH - 1 : 0] sIn,
        output logic [RAM_WIDTH - 1 : 0] sAddr,

        ////////////////////////////ROM-K
        input logic [RAM_WIDTH-1:0] kOut,
        output logic [MESSAGE_LOG_LENGTH-1:0] kAddr,

        //////////////////////////////RAM-A
        output logic [RAM_WIDTH-1:0] aIn,
        output logic [RAM_LENGTH-1:0] aAddr,
        output logic aWren,
        output logic succeeded,
        output logic terminated,
        /////////////////////////////////TEST
        /*
        output logic[7:0]iTap,
        output logic[7:0]jTap,
        output logic[7:0]siTap,
        output logic[7:0]sjTap,
        output logic [7:0] stateTap,
        output logic [7:0] kTap,
        output logic [2:0] fTap,
        output logic [5:0] modeTap,
        output logic wrenTap,
        */

        output logic [KEY_LENGTH-1:0][RAM_WIDTH-1:0] outKey
    );


    typedef enum logic [5:0] {
        IDLE = 6'b000_000,
        INIT_RAM = 6'b001_000,
        SHUFFLE_RAM = 6'b010_000,
        DECRYPT_RAM = 6'b011_000,
        GET_KEY = 6'b100_001,
        ARCFOUR_FAIL = 6'b110_010,
        ARCFOUR_SUCCESS = 6'b111_110
    } state_t;
    
    state_t state, next_state;
    //assign modeTap = state;

    logic start_sig;
    edge_detector detector(
        .clk(clk),
        .in(start),
        .out(start_sig)
    );


    logic keyStart, success;
    assign keyStart = state[0];
    assign terminated = state[1];
    assign succeeded = state[2];

    logic [NUM_DEVICES-1:0] finished;
    logic [NUM_DEVICES-1:0] next_finished;
    assign fTap = finished;


    logic [KEY_LENGTH-1:0][RAM_WIDTH-1:0] key, next_key, generator_key;
    assign outKey = key;

    logic key_finish, key_terminate;
    
    logic decryption_success;

    key_generator 
    #(
        .KEY_LENGTH(KEY_LENGTH),
        .RAM_WIDTH(RAM_WIDTH),
        .KEY_UPPER(KEY_UPPER), 
        .KEY_LOWER(KEY_LOWER)
    ) keyGen
    (
        .clk(clk),
        .reset(reset || start_sig),
        .start(keyStart),
        .key(generator_key),
        .finished(key_finish),
        .terminated(key_terminate)
    );
    
    logic termination_flag, next_termination_flag;
    logic key_sel, next_key_sel;

    always_comb begin
        next_key_sel = (state == IDLE)? key_select : key_sel;
        next_key = (state == GET_KEY)? (key_sel? switch_key : generator_key) : key;
        next_termination_flag = (state == GET_KEY)? (key_sel? 1 : key_terminate) : termination_flag;
    end

    always_ff @(posedge clk) begin
        if(reset)begin
            key <= 0;
            termination_flag <= 0;
            key_sel <= 0;
        end
        else begin
            key <= next_key;
            termination_flag <= next_termination_flag;
            key_sel <= next_key_sel;
        end
    end


    ramcontroller #(
        .RAM_WIDTH(RAM_WIDTH),
        .RAM_LENGTH(RAM_LENGTH),
        .MESSAGE_LENGTH(MESSAGE_LENGTH),
        .MESSAGE_LOG_LENGTH(MESSAGE_LOG_LENGTH),
        .KEY_LENGTH(KEY_LENGTH)
    ) controller
    (
        .clk(clk),
        .reset(reset),
        .finish_bus(next_finished),
        .mode(state),
        .sIn(sIn),
        .sAddr(sAddr),
        .sWren(sWren),
        .sOut(sOut),
        .kAddr(kAddr),
        .kOut(kOut),
        .aAddr(aAddr),
        .aIn(aIn),
        .aWren(aWren),
        .key(key),
        /*
        .iTap(iTap),
        .jTap(jTap),
        .siTap(siTap),
        .sjTap(sjTap),
        .stateTap(stateTap),
        .kTap(kTap),
        .wrenTap(wrenTap),
        */
        .success(decryption_success)
    );

    always_ff @(posedge clk) begin 
        if(reset) success <= 0;
        else success <= decryption_success;
    end

    //State transition logic
    always_comb begin
        case(state)
            IDLE: next_state = start_sig? GET_KEY : IDLE;

            GET_KEY: begin
                if(key_sel) next_state = INIT_RAM;
                else next_state = key_finish? INIT_RAM : GET_KEY;
            end

            INIT_RAM: next_state = finished[0]? SHUFFLE_RAM : INIT_RAM;

            SHUFFLE_RAM: next_state = finished[1]? DECRYPT_RAM : SHUFFLE_RAM;

            DECRYPT_RAM: next_state = finished[2]? ((termination_flag || success)? (success? ARCFOUR_SUCCESS : ARCFOUR_FAIL) : GET_KEY) : DECRYPT_RAM;

            ARCFOUR_FAIL: next_state = IDLE;

            ARCFOUR_SUCCESS: next_state = IDLE;

            default: next_state = IDLE;
        endcase
    end


    always_ff @( posedge clk ) begin
        if(reset)begin
            state <= IDLE;
            finished <= 0;
        end else begin
            state <= next_state;
            finished <= next_finished;
        end
    end


endmodule