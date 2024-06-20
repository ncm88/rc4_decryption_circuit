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

//TODO: Remove redundant states, use glitch-free method
module ram_shuffler
    #(
        parameter RAM_WIDTH = 8,
        parameter RAM_LENGTH = 8,
        parameter KEY_LENGTH = 3,       //Number of bytes in our key
        parameter START_INDEX = 0,
        parameter END_INDEX = 255,
        parameter USE_TAPS = 0
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
        output logic [RAM_LENGTH - 1 : 0] address

        /////////////////////////////////////TEST
        /*
        output logic [7:0] iTap,
        output logic [7:0] jTap,
        output logic [2:0] stateTap,
        output logic [7:0] siTap,
        output logic [7:0] sjTap
        */
    );

    /////CHANGE AS NEEDED
    typedef enum logic [2:0] {
        AWAIT_START = 3'b000,
        READ_I = 3'b001,
        READ_J = 3'b010,
        WRITE_I = 3'b011,
        WRITE_J = 3'b100,
        AWAIT_SI = 3'b101,
        AWAIT_SJ = 3'b110
    } state_t;

    
    state_t state, next_state;
    logic start_sig;

    trap_edge trapper(
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
    logic [RAM_WIDTH - 1 : 0] next_ram_in;
    logic next_write_enable;
    logic next_finished;

/*
    assign iTap = i;
    assign jTap = j;
    assign stateTap = state;
    assign siTap = si;
    assign sjTap = sj;
*/

    //state change logic
    always_comb begin
        case(state)
            AWAIT_START:begin
                if(start_sig) next_state = AWAIT_SI;
                else next_state = AWAIT_START;
                next_i = 0;
            end

            AWAIT_SI: begin
                next_state = READ_I;
                next_i = i;
            end

            READ_I: begin
                next_state = AWAIT_SJ;
                next_i = i;
            end

            AWAIT_SJ: begin
                next_state = READ_J;
                next_i = i;
            end


            READ_J: begin
                next_state = WRITE_I;
                next_i = i;
            end

            WRITE_I: begin
                next_state = WRITE_J;
                next_i = i;
            end

            WRITE_J: begin
                if(i < END_INDEX)begin
                    next_state = AWAIT_SI;
                    next_i = i+1;
                end
                else begin
                     next_state = AWAIT_START;
                     next_i = 0;
                end
            end

            default: next_state = AWAIT_START;

        endcase
    end



    always_ff @( posedge clk ) begin
        if(reset) begin
            state <= AWAIT_START;
            i <= 0;
            j <= 0;         //si and j lag i by one
            si <= 0;
            sj <= 0;        //sj lags i by two
            address <= 0;
            ram_in <= 0;
            write_enable <= 0;
            finished <= 0;
        end
        else begin
            state <= next_state;
            i <= next_i;
            j <= next_j;
            si <= next_si;
            sj <= next_sj;
            address <= next_address;
            ram_in <= next_ram_in;
            write_enable <= next_write_enable;
            finished <= next_finished;
        end
    end


    assign next_finished = (state == WRITE_J)&&(i >= END_INDEX);

    //Output logic
    always_comb begin
        case(state)
            AWAIT_START: begin
                next_j = 0;
                next_si = 0;
                next_sj = 0;
                next_address = 0;
                next_ram_in = 0;
                next_write_enable = 0;
            end

            AWAIT_SI: begin
                next_j = j;
                next_sj = sj;
                next_si = si;
                next_address = address;
                next_ram_in = ram_in;
                next_write_enable = write_enable;
            end


            READ_I: begin
                next_sj = sj;
                next_si = ram_out;
                
                next_j = j + next_si + key[i % KEY_LENGTH];

                next_address = next_j;
                next_ram_in = 0;
                next_write_enable = 0;
            end
            

            AWAIT_SJ: begin
                next_j = j;
                next_sj = sj;
                next_si = si;
                next_address = address;
                next_ram_in = ram_in;
                next_write_enable = write_enable;
            end


            READ_J: begin
                next_sj = ram_out;
                next_si = si;

                next_j = j;

                next_address = i;
                next_ram_in = next_sj;
                next_write_enable = 1;
            end

            WRITE_I: begin
                next_sj = sj;
                next_si = si;
                next_j = j;

                next_address = j;
                next_ram_in = si;
                next_write_enable = 1;
            end

            WRITE_J: begin
                next_sj = sj;
                next_si = si;
                next_j = j;

                next_address = next_i;
                next_ram_in = 0;
                next_write_enable = 0;
            end
            
        endcase
    end

endmodule


