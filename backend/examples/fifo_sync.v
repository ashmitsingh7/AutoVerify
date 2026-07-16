// Small synchronous FIFO, no parameters, mixed port declaration styles,
// used to stress-test the parser (multiple names sharing one direction,
// active-low reset with a different naming convention, etc).
module fifo_sync (
  input  clk,
  input  reset_n,
  input  wr_en, rd_en,
  input  [7:0] din,
  output reg [7:0] dout,
  output full,
  output empty
);

  reg [7:0] mem [0:15];
  reg [4:0] wr_ptr, rd_ptr;

  assign full  = (wr_ptr[3:0] == rd_ptr[3:0]) && (wr_ptr[4] != rd_ptr[4]);
  assign empty = (wr_ptr == rd_ptr);

  always @(posedge clk or negedge reset_n) begin
    if (!reset_n) begin
      wr_ptr <= 5'd0;
      rd_ptr <= 5'd0;
      dout   <= 8'd0;
    end else begin
      if (wr_en && !full) begin
        mem[wr_ptr[3:0]] <= din;
        wr_ptr <= wr_ptr + 1'b1;
      end
      if (rd_en && !empty) begin
        dout   <= mem[rd_ptr[3:0]];
        rd_ptr <= rd_ptr + 1'b1;
      end
    end
  end

endmodule
