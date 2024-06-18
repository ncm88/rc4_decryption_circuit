module arcfour
    #(
        parameter RAM_WIDTH = 8,
        parameter KEY_LENGTH = 3,
        parameter NUM_DEVICES = 4
    )
    (
        input logic clk,
        input logic reset,
        input logic start_sig,

        input logic [RAM_WIDTH-1:0]ram_out,
        input logic [KEY_LENGTH-1:0][RAM_WIDTH-1:0] key,

        output logic [RAM_WIDTH-1:0] address,
        output logic [RAM_WIDTH-1:0] ram_in,
        output logic write_enable,
        output logic arcfour_finished,

        output logic [2:0] state_tap,
        output logic [1:0] fTap,

        output logic[7:0]iTap,
        output logic[7:0]jTap,
        output logic[7:0]siTap,
        output logic[7:0]sjTap,
        output logic readTap, 
        output logic writeTap,
        output logic [2:0] shuffleState
    );

    logic next_arcfour_finished;

    typedef enum logic [3:0] {
        IDLE = 4'b0000,
        INIT_RAM = 4'b0001,
        SHUFFLE_RAM = 4'b0010,
        READ_MESSAGE = 4'b0100
    } state_t;

    state_t state, next_state;
    assign state_tap = state;

    logic [NUM_DEVICES-1:0] finished;
    logic [NUM_DEVICES-1:0] next_finished;

    assign fTap = finished;
    ramcontroller controller(
        .clk(clk),
        .reset(reset),
        .finished(next_finished),
        .mode(state),
        .ram_out(ram_out),
        .address(address),
        .ram_in(ram_in),
        .write_enable(write_enable),
        .key(key),
        .iTap(iTap),
        .jTap(jTap),
        .siTap(siTap),
        .sjTap(sjTap),
        .shuffleState(shuffleState)
    );



    //State transition logic
    always_comb begin
        case(state)
            IDLE: begin
                if(start_sig) begin
                    next_state = INIT_RAM;
                    next_arcfour_finished = 0;
                end
                else begin
                    next_state = IDLE;
                    next_arcfour_finished = arcfour_finished;
                end
            end

            INIT_RAM: begin
                if(finished[0]) next_state = SHUFFLE_RAM;
                else next_state = INIT_RAM;
                next_arcfour_finished = 0;
            end

            SHUFFLE_RAM: begin
                if(finished[1])begin
                    next_state = IDLE;
                    next_arcfour_finished = 1;
                end
                else begin 
                    next_state = SHUFFLE_RAM;
                    next_arcfour_finished = 0;
                end
            end

            default: begin
                next_state = IDLE;
                next_arcfour_finished = 0;
            end
        endcase
    end


    always_ff @( posedge clk ) begin
        if(reset)begin
            state <= IDLE;
            finished <= 0;
            arcfour_finished <= 0;
        end else begin
            state <= next_state;
            finished <= next_finished;
            arcfour_finished <= next_arcfour_finished;
        end
    end


endmodule