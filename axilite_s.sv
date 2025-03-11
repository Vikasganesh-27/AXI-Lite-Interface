module axilite_s (
  // AXI Lite Interface Signals
  input wire s_axi_aclk,        // Clock signal
  input wire s_axi_aresetn,     // Active-low reset signal
  
  // Write Address Channel
  input wire s_axi_awvalid,     // Write address valid
  output reg s_axi_awready,     // Write address ready
  input wire [31:0] s_axi_awaddr, // Write address
  
  // Write Data Channel
  input wire s_axi_wvalid,      // Write data valid
  output reg s_axi_wready,      // Write data ready
  input wire [31:0] s_axi_wdata, // Write data
  
  // Write Response Channel
  output reg s_axi_bvalid,      // Write response valid
  input wire s_axi_bready,      // Write response ready
  output reg [1:0] s_axi_bresp, // Write response (OKAY or ERROR)
  
  // Read Address Channel
  input wire s_axi_arvalid,     // Read address valid
  output reg s_axi_arready,     // Read address ready
  input wire [31:0] s_axi_araddr, // Read address
  
  // Read Data Channel
  output reg s_axi_rvalid,      // Read data valid
  input wire s_axi_rready,      // Read data ready
  output reg [31: 0] s_axi_rdata, // Read data
  output reg [1: 0] s_axi_rresp  // Read response (OKAY or ERROR)
);

// State Encoding for State Machine
localparam idle = 0, 
  send_waddr_ack = 1,
  send_raddr_ack = 2,
  send_wdata_ack = 3,
  update_mem = 4,
  send_wr_err = 5,
  send_wr_resp = 6,
  gen_data = 7,
  send_rd_err = 8,
  send_rdata = 9;

// Internal Registers
reg [3:0] state = idle;  // Current state
reg [3:0] next_state = idle; // Next state
reg [1:0] count = 0;     // Counter for read delay simulation
reg [31:0] waddr, raddr, wdata, rdata; // Address and data registers
reg [31:0] mem [128];    // Internal memory array

// State Machine Implementation
always@(posedge s_axi_aclk)begin
  if(s_axi_aresetn == 1'b0)begin
    // Reset all signals and memory on reset
    state <= idle;
    for(int i = 0; i < 128; i++)begin
      mem[i] <= 0;
    end
    s_axi_awready <= 0;
    s_axi_wready  <= 0;
    s_axi_bvalid  <= 0;
    s_axi_bresp   <= 0;
    s_axi_arready <= 0;
    s_axi_rvalid  <= 0;
    s_axi_rdata   <= 0;
    s_axi_rresp   <= 0;
    waddr <= 0;
    raddr <= 0;
    wdata <= 0;
    rdata <= 0;
  end
  else begin
    case(state)
      idle : begin
        // Reset all handshake signals
        s_axi_awready <= 0;
        s_axi_wready <= 0;
        s_axi_bvalid <= 0;
        s_axi_bresp <= 0;
        s_axi_arready <= 0;
        s_axi_rvalid <= 0;
        s_axi_rdata <= 0;
        s_axi_rresp <= 0;
        count <= 0;
        
        if(s_axi_awvalid == 1'b1) begin
          // Capture write address and acknowledge
          state <= send_waddr_ack;
          waddr <= s_axi_awaddr;
          s_axi_awready <= 1'b1;
        end else if(s_axi_arvalid == 1'b1) begin
          // Capture read address and acknowledge
          state <= send_raddr_ack;
          raddr <= s_axi_araddr;
          s_axi_arready <= 1'b1;
        end else begin
          state <= idle;
        end
      end
      
      send_waddr_ack : begin
        // Write address acknowledged, wait for data
        s_axi_awready <= 1'b0;
        if(s_axi_wvalid)begin
          wdata <= s_axi_wdata;
          s_axi_wready <= 1'b1;
          state <= send_wdata_ack;
        end
      end
      
      send_wdata_ack: begin
        // Write data acknowledged, check address range
        s_axi_wready <= 1'b0;
        if(waddr < 128) begin
          state <= update_mem;
          mem[waddr] <= wdata;
        end else begin
          state <= send_wr_err;
          s_axi_bresp <= 2'b11; // Error response
          s_axi_bvalid <= 1'b1;
        end
      end
      
      update_mem : begin
        // Store data in memory and send response
        mem[waddr] <= wdata;
        state <= send_wr_resp;
      end
      
      send_wr_resp : begin
        // Send write response OKAY
        s_axi_bresp  <= 2'b00;
        s_axi_bvalid <= 1'b1;
        if(s_axi_bready) begin
          state <= idle;
        end
      end
      
      send_wr_err: begin
        // Send error response
        if(s_axi_bready) begin
          state <= idle;
        end
      end
      
      send_raddr_ack : begin
        // Acknowledge read address and check bounds
        s_axi_arready = 1'b0;
        if(raddr < 128)
          state <= gen_data;
        else begin
          state <= send_rd_err;
          s_axi_rvalid <= 1'b1;
          s_axi_rdata  <= 0;
          s_axi_rresp  <= 2'b11;
        end
      end
      
      gen_data: begin
        // Simulate read delay
        if(count < 2) begin
          rdata <= mem[raddr];
          state <= gen_data;
          count <= count + 1;
        end else begin
          // Send read data
          s_axi_rvalid <= 1'b1;
          s_axi_rdata  <= rdata;
          s_axi_rresp  <= 2'b00;
          if(s_axi_rready)
            state <= idle;
        end
      end
      
      send_rd_err : begin
        // Send read error response
        if(s_axi_rready) begin
          state <= idle;
        end
      end
      
      default: state <= idle;
    endcase
  end
end
endmodule

/////////////////////////////
// AXI Lite Interface Definition
interface axi_if;
  logic clk, resetn;
  logic awvalid, awready;
  logic arvalid, arready;
  logic wvalid, wready;
  logic bready, bvalid;
  logic rvalid, rready;
  logic [31:0] awaddr, araddr, wdata, rdata;
  logic [1:0] wresp, rresp;
endinterface
