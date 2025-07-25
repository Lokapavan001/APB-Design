`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 07/12/2025 02:34:10 PM
// Design Name: 
// Module Name: design
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: 
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////


module apb_slave #(
    parameter DATA_WIDTH = 32,
    parameter ADDR_WIDTH = 32,
    parameter REG_COUNT  = 4
)(
    input                     PCLK,
    input                     PRESETn,
    input  [ADDR_WIDTH-1:0]   PADDR,
    input                     PSEL,
    input                     PENABLE,
    input                     PWRITE,
    input  [DATA_WIDTH-1:0]   PWDATA,
    output reg [DATA_WIDTH-1:0] PRDATA,
    output                    PREADY,
    output reg                PSLVERR
);

    // FSM States as localparams
    localparam [1:0]
        IDLE   = 2'b00,
        SETUP  = 2'b01,
        ACCESS = 2'b10;

    // FSM state registers
    reg [1:0] state;
    reg [1:0] next_state;

    // Register file
    reg [DATA_WIDTH-1:0] regfile [0:REG_COUNT-1];

    // FSM state update
    always @(posedge PCLK or negedge PRESETn) begin
        if (!PRESETn)
            state <= IDLE;
        else
            state <= next_state;
    end

    // FSM next state logic
    always @(*) begin
        case (state)
            IDLE:    next_state = (PSEL && !PENABLE) ? SETUP : IDLE;
            SETUP:   next_state = PENABLE ? ACCESS : SETUP;
            ACCESS:  next_state = (PSEL && !PENABLE) ? SETUP : IDLE;
            default: next_state = IDLE;
        endcase
    end

    // Output logic
    assign PREADY = (state == ACCESS); // Ready only in ACCESS phase

    integer i;

    // Register read/write logic
    always @(posedge PCLK or negedge PRESETn) begin
        if (!PRESETn) begin
            PRDATA  <= {DATA_WIDTH{1'b0}};
            PSLVERR <= 1'b0;
            for (i = 0; i < REG_COUNT; i = i + 1)
                regfile[i] <= {DATA_WIDTH{1'b0}};
        end else begin
            PSLVERR <= 1'b0; // Clear error every transaction

            if (state == ACCESS) begin
                if (PADDR[ADDR_WIDTH-1:2] < REG_COUNT) begin
                    if (PWRITE)
                        regfile[PADDR[ADDR_WIDTH-1:2]] <= PWDATA;
                    else
                        PRDATA <= regfile[PADDR[ADDR_WIDTH-1:2]];
                end else begin
                    PSLVERR <= 1'b1;
                    PRDATA  <= {DATA_WIDTH{1'b0}};
                end
            end
        end
    end

endmodule
