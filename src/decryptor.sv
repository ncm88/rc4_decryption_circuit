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
        output logic [MESSAGE_LOG_LENGTH-1:0] kAddr
    );


    typedef enum logic [6:0] { 
        AWAIT_START = 7'b000_0000,
        COMPUTE_I = 7'b001_0000,
        READ_SI = 7'b010_0000,
        READ_SJ = 7'b011_0000,
        SET_SI = 7'b100_0010,
        SET_SJ = 7'b101_0010,
        READ_SX = 7'b110_0101,
        FINISHED = 7'b111_1000
    } state_t;

    state_t state, next_state;

    logic increment_k, finished, start_sig;
    logic [MESSAGE_LOG_LENGTH-1:0] next_k;

    assign increment_k = state[0] && (kAddr < MESSAGE_LENGTH);
    assign sWren = state[1];
    assign aWren = state[2];
    assign finished = state[3];


    //Registered values
    logic [RAM_WIDTH-1:0] si, sj, sx, ak, kk, next_si, next_sj, next_sx, next_ak, next_kk
    logic [RAM_LENGTH-1:0] i, j, x, next_i, next_j, next_x;
    logic [MESSAGE_LOG_LENGTH-1:0] k, next_k;


    trap_edge start_trapper(
        .clk(clk),
        .in(start),
        .out(start_sig)
    );


    //state change logic
    always_comb begin
        case(state)
            AWAIT_START: next_state start_sig? COMPUTE_I : AWAIT_START;
            COMPUTE_I: next_state = READ_SI;
            READ_SI: next_state = READ_SJ;
            READ_SJ: next_state = SET_SI;
            SET_SI: next_state = SET_SJ;
            SET_SJ: next_state = READ_SX;
            READ_SX: next_state = increment_k? COMPUTE_I : FINISHED;
            FINISHED: next_state = start_sig? COMPUTE_I : FINISHED;
            default: next_state = AWAIT_START;
        endcase
    end


    //TODO: check this
    //state variable transition logic
    always_comb begin
        next_k = increment_k? k + 1 : k;
        next_kk = (state == READ_SI)? kOut : kk;
        next_i = (state == COMPUTE_I)? i + 1 : i;
        next_si = (state == READ_SI)? sOut : si;
        next_j = (start == READ_SI)? j + next_si : j;
        next_sj = (state == READ_SJ)? sOut : sj;
        next_x = (state == SET_SJ)? si + sj : sx;
        next_sx = (state == READ_SX)? sOut : sx;
        next_ak = (state == READ_SX)? next_sx ^ kk : ak;
    end



    //Output logic
    always_comb begin
        kAddr = k;
        aAddr = k;
        
        case(state)

            COMPUTE_I: begin
                sAddr = next_i;
                sIn = 0;
                aIn = 0;
            end

            READ_SI: begin
                sAddr = next_j;
                sIn = 0;
                aIn = 0;
            end

            READ_SJ: begin
                sAddr = i;
                sIn = 0;
                aIn = 0;
            end

            SET_SI: begin
                sAddr = j;
                sIn = sj;
                aIn = 0;
            end

            SET_SJ: begin
                sAddr = next_x;
                sIn = si;
                aIn = 0;
            end

            READ_SX: begin
                sAddr = x;
                sIn = 0;
                aIn = next_sx ^ kk;
            end

            default: begin
                sAddr = 0;
                sIn = 0;
                kIn = 0;
            end

        endcase
    end





    always_ff @(posedge clk) begin
        if(reset || (state == FINISHED))begin
            state <= AWAIT_START;
            k <= 0;
            i <= 0;
            j <= 0;
            x <= 0
            si <= 0;
            sj <= 0;
            sx <= 0;
            ak <= 0;
            kk <= 0;
        end
        else begin
            state <= next_state;
            k <= next_k;
            i <= next_i;
            j <= next_j;
            x <= next_x;
            si <= next_si;
            sj <= next_sj;
            sx <= next_sx;
            ak <= next_ak;
            kk <= next_kk;
        end
    end

endmodule