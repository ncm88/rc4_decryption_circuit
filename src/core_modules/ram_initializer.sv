//TODO: implement glitch-free streamling
module ram_initializer
    #(
        parameter RAM_WIDTH,
        parameter RAM_LENGTH,
        parameter START_INDEX = 0,
        parameter END_INDEX = 8'd255
    )
    (
        input logic clk,
        input logic reset,
        //////////////////////////////////// CONTROL
        input logic start,
        output logic finished,
        ////////////////////////////////////////////RAM IO
        output logic write_enable,
        output logic [RAM_WIDTH - 1 : 0] ram_in,
        output logic [RAM_LENGTH - 1 : 0] address
    );


    logic next_write_enable, next_finished;
    logic [RAM_WIDTH - 1 : 0] next_ram_in;
    logic [RAM_LENGTH - 1 : 0] next_address;

    typedef enum logic {
        AWAIT_START = 1'b0,
        RUNNING = 1'b1
    } state_t;

    state_t state, next_state;

    logic start_sig;

    edge_detector detector(
        .clk(clk),
        .in(start),
        .out(start_sig)
    );


    always_comb begin
        case(state)
            AWAIT_START: begin
                if(start_sig) next_state = RUNNING;
                else next_state = AWAIT_START;
            end
            
            RUNNING: begin
                if(address < END_INDEX) next_state = RUNNING;
                else next_state = AWAIT_START;
            end

            default: next_state = AWAIT_START;
        endcase
    end



    always_ff @( posedge clk ) begin 
        if(reset)begin
            state <= AWAIT_START;
            ram_in <= 0;
            address <= 0;
            write_enable <= 0;
            finished <= 0;
        end
        else begin
            state <= next_state;
            ram_in <= next_ram_in;
            address <= next_address;
            write_enable <= next_write_enable;
            finished <= next_finished;
        end
    end

    always_comb begin
        case(state)
            AWAIT_START: begin
                next_address = START_INDEX;
                next_ram_in = START_INDEX;
                if(start_sig) next_write_enable = 1;
                else next_write_enable = 0;
                next_finished = 0;
            end

            RUNNING: begin
                if(address < END_INDEX) begin
                    next_address = address + 1;
                    next_ram_in = ram_in + 1;
                    next_write_enable = 1;
                    next_finished = 0;
                end
                else begin
                    next_address = START_INDEX;
                    next_ram_in = START_INDEX;
                    next_write_enable = 0;
                    next_finished = 1;
                end
            end

            default: begin
                next_address = START_INDEX;
                next_ram_in = START_INDEX;
                next_write_enable = 0;
                next_finished = 0;
            end

        endcase
    end




endmodule