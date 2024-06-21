module key_generator
    #(
        parameter KEY_UPPER = 24'hFFFFFF,
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

    typedef enum logic [2:0] {
        AWAIT_START = 3'b000,
        RUNNING = 3'b001,
        FINISHED = 3'b010,
        TERMINATED = 3'b110
    } state_t;
    state_t state, next_state;

    logic [23:0] next_key;

    assign finished = state[1];
    assign terminated = state[2];

    logic start_sig;
    trap_edge start_trapper(
        .clk(clk),
        .in(start),
        .out(start_sig)
    );

    always_comb begin
        case(state) 
            AWAIT_START: next_state = (start_sig) ? RUNNING : AWAIT_START;
            RUNNING: next_state = (key >= KEY_UPPER )? TERMINATED : FINISHED;
            FINISHED: next_state = AWAIT_START;
            TERMINATED: next_state = AWAIT_START;
        endcase
    end

    always_comb begin
        next_key = ((state == FINISHED) || (state == TERMINATED))? ((key + 24'h000001 > KEY_UPPER)? KEY_LOWER : key + 24'h000001) : key;
    end

    always_ff @(posedge clk) begin
        if(reset) begin
            key <= KEY_LOWER;
            state <= AWAIT_START;
        end
        else begin
            key <= next_key;
            state <= next_state;
        end
    end


endmodule