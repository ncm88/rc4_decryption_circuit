module key_generator
    #(
        parameter KEY_UPPER = 24'h000001,       //operates over [KEY_LOWER, KEY_UPPER] inclusive
        parameter KEY_LOWER = 24'h000000
    )
    (
        input logic clk,
        input logic reset,
        input logic start,
        output logic finished,
        output logic terminated,
        output logic [23:0] key
    );

    typedef enum logic [4:0] {
        AWAIT_START = 5'b000_00,
        RUNNING = 5'b001_00,
        FINISHED = 5'b010_01,
        TERMINATED = 5'b011_11,
        AWAIT_START_POST_FINISH = 5'b100_00
    } state_t;
    state_t state, next_state;

    logic [24:0] next_key;

    assign finished = state[0];
    assign terminated = state[1];

    logic start_sig;
    trap_edge start_trapper(
        .clk(clk),
        .in(start),
        .out(start_sig)
    );

    always_comb begin
        next_key = (state == AWAIT_START_POST_FINISH && start_sig)? ((key < KEY_UPPER)? key + 24'h000001 : KEY_LOWER) : key;
    end
    
    always_comb begin
        case(state) 
            AWAIT_START: next_state = (start_sig) ? RUNNING : AWAIT_START;
            RUNNING: next_state = (key < KEY_UPPER )? FINISHED : TERMINATED;
            FINISHED: next_state = AWAIT_START_POST_FINISH;
            TERMINATED: next_state = AWAIT_START_POST_FINISH;
            AWAIT_START_POST_FINISH: next_state = (start_sig) ? RUNNING : AWAIT_START_POST_FINISH;
        endcase
    end

    

    always_ff @(posedge clk) begin
        if(reset) begin
            key <= KEY_LOWER;
            state <= AWAIT_START;
        end
        else begin
            key <= next_key[23:0];
            state <= next_state;
        end
    end


endmodule