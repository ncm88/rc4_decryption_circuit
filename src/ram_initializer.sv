
module ram_initializer
    #(
        parameter RAM_WIDTH = 8
    )
    (
        input logic enable,
        input logic clk,
        output logic write_enable,
        output logic [RAM_WIDTH - 1 : 0] ram_in,
        output logic [RAM_WIDTH - 1 : 0] address,
        output logic done
    );

    localparam IDLE = 0;
    localparam SEED_SEQUENCE = 1;

    logic state, next_state;
    logic next_write_enable, next_done;
    logic [RAM_WIDTH - 1 : 0] next_ram_in;
    logic [RAM_WIDTH - 1 : 0] next_address;


    //state change logic
    always_comb begin
        case(state)
            IDLE: begin
                if(enable) next_state = SEED_SEQUENCE;
                else next_state = IDLE;
            end

            SEED_SEQUENCE: begin
                next_state = SEED_SEQUENCE;
            end
        endcase
    end



    always_ff @(posedge clk) begin
        if(~enable) begin
            state <= IDLE;
            address <= 0;
            ram_in <= 0;
            write_enable <= 0;
            done <= 0;
        end

        else begin
            state <= next_state;
            address <= next_address;
            ram_in <= next_ram_in;
            write_enable <= next_write_enable;
            done <= next_done;
        end;
    end



    always_comb begin
        case(state)
            IDLE: begin
                next_address = 0;
                next_ram_in = 0;
                next_done = 0;
                if(enable) next_write_enable = 1;
                else next_write_enable = 0;
            end

            SEED_SEQUENCE: begin
                if(address < 255) begin
                    next_address = address + 1;
                    next_ram_in = ram_in + 1;
                    next_write_enable = 1;
                    next_done = 0;
                end
                else begin
                    next_address = address;
                    next_ram_in = ram_in;
                    next_write_enable = 0;
                    next_done = 1;
                end
            end
        endcase
    end




endmodule