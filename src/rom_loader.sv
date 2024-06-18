module rom_loader
    #(
        parameter KEY_LENGTH = 32,
        parameter ROM_LENGTH = 5,   //log2 of key length
        parameter ROM_WIDTH = 8
    )
    (
        input logic clk,
        input logic reset,
        input logic start,

        input logic[ROM_WIDTH-1:0] rom_out,
        output logic[ROM_LENGTH-1:0] address,

        output reg [KEY_LENGTH-1:0][ROM_WIDTH-1:0] key_arr,
        output logic finished,

        output logic [1:0] state_tap
    );


    typedef enum logic [1:0]{
        AWAIT_START = 2'b00,
        RUNNING = 2'b01,
        FINISHED = 2'b10
    } state_t;

    state_t state, next_state;
    assign state_tap = state;

    logic [ROM_LENGTH-1:0] i;
    logic [ROM_LENGTH-1:0] next_i;

    logic start_sig, jump_next;

    assign jump_next = (state[0]) && (i < KEY_LENGTH-1);
    assign next_i = jump_next? i+1 : 0;
    assign finished = state[1];



    trap_edge start_trapper(
        .clk(clk),
        .in(start),
        .out(start_sig)
    );


    always_comb begin
        case(state)
            AWAIT_START: next_state = start_sig? RUNNING : AWAIT_START;
            RUNNING: next_state = jump_next? RUNNING : FINISHED;
            FINISHED: next_state = start_sig? RUNNING : FINISHED;
        endcase
    end


    always_ff @(posedge clk) begin
        if(reset)begin
            state <= AWAIT_START;
            key_arr <= 0;
            i <= 0;
            address <= 0;
        end
        else begin
            state <= next_state;
            i <= next_i;
            address <= i;
            if(state == AWAIT_START) key_arr <= 0;
            else key_arr[address] <= rom_out;
        end
    end

endmodule