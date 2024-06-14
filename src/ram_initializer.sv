///TODO: Modify this so that it also shuffles and takes key arg params


module ram_initializer
    #(
        parameter RAM_WIDTH = 8,
        parameter START_INDEX = 0,
        parameter END_INDEX = 255
    )
    (
        input logic clk,
        input logic reset,
        input logic start,
        input logic [9:0] switch_key,
        //////////////////////////////////// CONTROL
        output logic state,
        output logic finished,
        ////////////////////////////////////////////RAM IO
        output logic write_enable,
        output logic [RAM_WIDTH - 1 : 0] ram_in,
        output logic [RAM_WIDTH - 1 : 0] address
    );


    logic next_write_enable, next_finished;
    logic [RAM_WIDTH - 1 : 0] next_ram_in;
    logic [RAM_WIDTH - 1 : 0] next_address;

    logic [23:0] swKey;
    assign swKey = {14'b0, switch_key};


    typedef enum logic [1:0] {
        AWAIT_START = 2'b00,
        FIRST_PASS = 2'b01,
        SECOND_PASS = 2'b10
    } state_t;

    state_t curr_state, next_state;
    assign state = curr_state;

    logic start_sig, reset_sig;

    trap_edge startTrapper(
        .clk(clk),
        .in(start),
        .out(start_sig)
    );

    trap_edge rstTrapper{
        .clk(clk),
        .in(reset),
        .out(reset_sig)
    }

    logic [7 : 0] i;
    logic [7 : 0] next_i;
    
    logic [7 : 0] j;
    logic [7 : 0] next_j;

    logic [END_INDEX : START_INDEX][RAM_WIDTH - 1 : 0] i_arr;


    always_comb begin
        case(curr_state)
            AWAIT_START: begin
                if(start_sig) next_state = FIRST_PASS;
                else next_state = AWAIT_START;
            end
            FIRST_PASS: begin
                if(address < END_INDEX) next_state = FIRST_PASS;
                else next_state = SECOND_PASS;
            end
            SECOND_PASS: begin
                if(address < END_INDEX) next_state = SECOND_PASS;
                else next_state = AWAIT_START;
            end
        endcase
    end



    always_ff @( posedge clk ) begin 
        if(reset_sig)begin
            curr_state <= AWAIT_START;
            ram_in <= 0;
            address <= 0;
            write_enable <= 0;
            finished <= 0;
            i_arr <= 0;
        end else begin

            curr_state <= next_state;
            write_enable <= next_write_enable;
            finished <= next_finished;      

            i_arr[j] <= i;
            i_arr[i] <= j

            address <= i;
            ram_in <= j;
            
            i <= next_i;
            j <= next_j;
        end
    end
    

    always_comb begin
        case(state)
            AWAIT_START: begin
                next_address = START_INDEX;
                next_ram_in = START_INDEX;     
                next_write_enable = 0;
                next_finished = 0;

                next_i = 0;
                next_j = 0;
            end

            FIRST_PASS: begin
                if(address < END_INDEX) begin
                    next_address = address + 1;
                    next_ram_in = ram_in + 1;
                    next_write_enable = 0;
                    next_i = i + 1;
                end else begin
                    next_address = START_INDEX;
                    next_ram_in = START_INDEX;
                    
                    next_i = 0;
                    next_write_enable = 1;
                end
                next_finished = 0;
            end

            SECOND_PASS: begin
                if(address < END_INDEX)begin
                    next_j = j + i_arr[address] + switch_key[address % 3];
                    

                    next_i = i + 1;
                end else begin


                end
            end

        endcase
    end




endmodule