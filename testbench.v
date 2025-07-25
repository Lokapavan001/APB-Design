`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 07/12/2025 02:33:46 PM
// Design Name: 
// Module Name: testbench
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


`timescale 1ns/1ps

module tb_apb_slave_fsm;

  // Parameters
  localparam DATA_WIDTH = 32;
  localparam ADDR_WIDTH = 32;
  localparam REG_COUNT  = 4;

  // Signals
  reg                      PCLK;
  reg                      PRESETn;
  reg  [ADDR_WIDTH-1:0]    PADDR;
  reg                      PSEL;
  reg                      PENABLE;
  reg                      PWRITE;
  reg  [DATA_WIDTH-1:0]    PWDATA;
  wire [DATA_WIDTH-1:0]    PRDATA;
  wire                     PREADY;
  wire                     PSLVERR;

  // DUT instantiation
  apb_slave_fsm #(
    .DATA_WIDTH(DATA_WIDTH),
    .ADDR_WIDTH(ADDR_WIDTH),
    .REG_COUNT(REG_COUNT)
  ) dut (
    .PCLK(PCLK),
    .PRESETn(PRESETn),
    .PADDR(PADDR),
    .PSEL(PSEL),
    .PENABLE(PENABLE),
    .PWRITE(PWRITE),
    .PWDATA(PWDATA),
    .PRDATA(PRDATA),
    .PREADY(PREADY),
    .PSLVERR(PSLVERR)
  );

  // Clock generation
  always #5 PCLK = ~PCLK;

  // APB write task
  task apb_write(input [ADDR_WIDTH-1:0] addr, input [DATA_WIDTH-1:0] data);
    begin
      @(posedge PCLK);
      PSEL    <= 1;
      PWRITE  <= 1;
      PADDR   <= addr;
      PWDATA  <= data;
      PENABLE <= 0;

      @(posedge PCLK);
      PENABLE <= 1;

      wait (PREADY);
      @(posedge PCLK);
      PSEL    <= 0;
      PENABLE <= 0;
      $display("Write: Addr=0x%0h Data=0x%0h Error=%b", addr, data, PSLVERR);
    end
  endtask

  // APB read task
  task apb_read(input [ADDR_WIDTH-1:0] addr);
    begin
      @(posedge PCLK);
      PSEL    <= 1;
      PWRITE  <= 0;
      PADDR   <= addr;
      PENABLE <= 0;

      @(posedge PCLK);
      PENABLE <= 1;

      wait (PREADY);
      @(posedge PCLK);
      $display("Read : Addr=0x%0h Data=0x%0h Error=%b", addr, PRDATA, PSLVERR);
      PSEL    <= 0;
      PENABLE <= 0;
    end
  endtask

  // Initialization
  initial begin
    PCLK    = 0;
    PRESETn = 0;
    PSEL    = 0;
    PENABLE = 0;
    PWRITE  = 0;
    PADDR   = 0;
    PWDATA  = 0;

    // Apply reset
    #20 PRESETn = 1;

    // Write to all 4 valid registers
    apb_write(32'h00, 32'h11111111); // reg 0
    apb_write(32'h04, 32'h22222222); // reg 1
    apb_write(32'h08, 32'h33333333); // reg 2
    apb_write(32'h0C, 32'h44444444); // reg 3

    // Read from all valid registers
    apb_read(32'h00);
    apb_read(32'h04);
    apb_read(32'h08);
    apb_read(32'h0C);

    // Extra write-read to test overwriting
    apb_write(32'h04, 32'hA5A5A5A5);
    apb_read(32'h04);

    // Invalid address write/read (e.g., 0x10 and above)
    apb_write(32'h10, 32'hDEADBEEF); // Invalid
    apb_read(32'h10);                // Invalid

    apb_write(32'h20, 32'hBAD0BAD0); // Invalid
    apb_read(32'h20);                // Invalid

    #50 $finish;
  end

endmodule


