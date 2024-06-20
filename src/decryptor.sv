module decryptor
    #(
        parameter RAM_WIDTH = 8,
        parameter RAM_LENGTH = 8,
        parameter MESSAGE_LENGTH = 32,
        parameter MESSAGE_LOG_LENGTH = 5
    )
    (
        input logic clk,
        input logic start,
        input logic reset,

        input logic [RAM_WIDTH-1:0] sOut,
        output logic [RAM_WIDTH-1:0] sIn,
        output logic [RAM_LENGTH-1:0] sAddr,
        output logic sWren,

        output logic [RAM_WIDTH-1:0] aIn,
        output logic [RAM_LENGTH-1:0] aAddr,
        output logic aWren,

        input logic [RAM_WIDTH-1:0] kOut,
        output logic [MESSAGE_LOG_LENGTH-1:0] kAddr,


        output logic [7:0] iTap,
        output logic [7:0] jTap,
        output logic [7:0] kTap,
        output logic [7:0] stateTap,
        output logic [7:0] siTap,
        output logic [7:0] sjTap
    );

    logic increment_k, finished, start_sig;
    logic [RAM_WIDTH-1:0] si, sj, next_si, next_sj;
    logic [RAM_LENGTH-1:0] i, j, next_i, next_j;
    logic [MESSAGE_LOG_LENGTH-1:0] k, next_k;


    typedef enum logic [7:0] { 
        AWAIT_START = 8'b000_0000,
        COMPUTE_I = 8'b0001_0000,
        READ_SI = 8'b0010_0000,
        READ_SJ = 8'b0011_0000,
        SET_SI = 8'b0100_0010,
        SET_SJ = 8'b0101_0010,
        AWAIT_SX = 8'b0110_0000,
        WRITE_ANSWER = 8'b0111_0101,
        FINISHED = 8'b1000_1100
    } state_t;
    state_t state, next_state;

    assign increment_k = state[0] && (k < MESSAGE_LENGTH);
    assign sWren = state[1];
    assign aWren = state[2];
    assign finished = state[3];

    assign next_k = increment_k? k + 1 : k;
    assign next_i = (state == COMPUTE_I)? i+1 : i;
    assign next_j = (state == READ_SI)? next_si + j : j;

    assign next_si = (state == READ_SI)? sOut : si;
    assign next_sj = (state == READ_SJ)? sOut : sj;
    
    assign x = si + sj;
    assign aIn = x ^ kOut;
    assign aAddr = k;
    assign kAddr = k;


    //////////////////////////TEST////////////////////////////
    assign siTap = si;
    assign sjTap = sj;
    assign iTap = i;
    assign jTap = j;
    assign stateTap = state;
    assign kTap = k;



    //sAddr and sIn logic
    always_comb begin
        case(state)
            COMPUTE_I: begin
                sAddr = next_i;
                sIn = 0;
            end 
            READ_SI: begin
                sAddr = next_j;
                sIn = 0;
            end
            READ_SJ: begin
                sAddr = i;
                sIn = 0;
            end
            SET_SI: begin
                sAddr = i;
                sIn = sj;
            end
            SET_SJ: begin
                sAddr = j;
                sIn = si;
            end
            AWAIT_SX: begin
                sAddr = x;
                sIn = 0;
            end

            default: begin
                sAddr = 0;
                sIn = 0;
            end
        endcase
    end




    trap_edge start_trapper(
        .clk(clk),
        .in(start),
        .out(start_sig)
    );


    //state change logic
    always_comb begin
        case(state)
            AWAIT_START: next_state = start_sig? COMPUTE_I : AWAIT_START;
            COMPUTE_I: next_state = READ_SI;
            READ_SI: next_state = READ_SJ;
            READ_SJ: next_state = SET_SI;
            SET_SI: next_state = SET_SJ;
            SET_SJ: next_state = AWAIT_SX;
            AWAIT_SX: next_state = WRITE_ANSWER;
            WRITE_ANSWER: next_state = increment_k? COMPUTE_I : FINISHED;
            FINISHED: next_state = FINISHED;
            default: next_state = AWAIT_START;
        endcase
    end


    always_ff @(posedge clk) begin
        if(reset)begin
            state <= AWAIT_START;
            k <= 0;
            i <= 0;
            j <= 0;
            si <= 0;
            sj <= 0;
        end
        else begin
            state <= next_state;
            k <= next_k;
            i <= next_i;
            j <= next_j;
            si <= next_si;
            sj <= next_sj;
        end
    end

endmodule