/*
    RC4 Shuffle Algo:
    1) j = 0; for i in range(255):
        ------------------------------------READ_STATE-----------------
        2) get s[i]
        3) j = (j + s[i] + key[i % L])%256
        4) get s[j]
        -----------------------------------WRITE_STATE------------------
        5) set s[i] = s[j]
        6) set s[j] = s[i]
*/

module ram_shuffler
    #(
        parameter RAM_WIDTH,
        parameter RAM_LENGTH,
        parameter KEY_LENGTH,       //Number of bytes in our key
        parameter END_INDEX = 8'd255
    )
    (
        input logic clk,
        input logic reset,
        //////////////////////////////////// CONTROL
        input logic start,
        output logic finished,
        ////////////////////////////////////////////RAM IO
        input logic [RAM_WIDTH - 1 : 0] ram_out,
        input logic [KEY_LENGTH-1:0][RAM_WIDTH-1:0] key,
        
        output logic write_enable,
        output logic [RAM_WIDTH - 1 : 0] ram_in,
        output logic [RAM_LENGTH - 1 : 0] address,

        output logic [7:0] iTap,
        output logic [7:0] jTap,
        output logic [4:0] stateTap,
        output logic [7:0] siTap,
        output logic [7:0] sjTap
    );

    typedef enum logic [4:0] {
        AWAIT_START = 5'b000_00,
        GET_SI = 5'b001_00,
        GET_SJ = 5'b010_00,
        SET_SI = 5'b011_01,
        SET_SJ = 5'b100_01,
        IDLE = 5'b101_00,
        FINISHED = 5'b110_10
    } state_t;
    state_t state, next_state;


    logic start_sig;
    edge_detector detector(
        .clk(clk),
        .in(start),
        .out(start_sig)
    );


    logic [RAM_LENGTH - 1 : 0] i;
    logic [RAM_LENGTH - 1 : 0] next_i;
    logic [RAM_LENGTH - 1 : 0] j;
    logic [RAM_LENGTH - 1 : 0] next_j;

    logic [RAM_WIDTH - 1 : 0] si;
    logic [RAM_WIDTH - 1 : 0] next_si;
    logic [RAM_WIDTH - 1 : 0] sj;
    logic [RAM_WIDTH - 1 : 0] next_sj;

    logic [RAM_LENGTH - 1 : 0] next_address;


    assign iTap = i;
    assign jTap = j;
    assign stateTap = state;
    assign siTap = si;
    assign sjTap = sj;                          ///////////////////TEST////////////////


    assign write_enable = state[0];
    assign finished = state[1];


    always_comb begin
        next_i = ((state == IDLE) || (state == FINISHED))? ((i < END_INDEX)? i + 1 : 0): i;
        next_si = (state == GET_SI)? ram_out : si;
        next_j = (state == AWAIT_START)? 0 : (state == GET_SI)? j + next_si + key[(KEY_LENGTH-1) - i % KEY_LENGTH] : j;
        next_sj = (state == GET_SJ)? ram_out : sj;
        ram_in = (state == SET_SI)? sj : si;

        case(state)
            AWAIT_START: address = 0;
            GET_SI: address = next_j;
            GET_SJ: address = j;
            SET_SI: address = i;
            SET_SJ: address = j;
            IDLE: address = next_i;
            default: address = 0;
        endcase
    end


    always_comb begin
        case(state)
            AWAIT_START: next_state = (start_sig)? GET_SI : AWAIT_START;
            GET_SI: next_state = GET_SJ;
            GET_SJ: next_state = SET_SI;
            SET_SI: next_state = SET_SJ;
            SET_SJ: next_state = (i < END_INDEX)? IDLE : FINISHED;
            IDLE: next_state = GET_SI;
            FINISHED: next_state = AWAIT_START;
            default: next_state = AWAIT_START;
        endcase
    end



    always_ff @(posedge clk) begin
        if(reset) begin
            state <= AWAIT_START;
            i <= 0;
            j <= 0;
            si <= 0;
            sj <= 0;
        end else begin
            state <= next_state;
            i <= next_i;
            j <= next_j;
            si <= next_si;
            sj <= next_sj;
        end
    end

endmodule
