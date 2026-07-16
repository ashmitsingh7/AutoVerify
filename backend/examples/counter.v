// Simple parametrized up-counter with synchronous active-low reset and load.
module counter #(
  parameter WIDTH = 8
) (
  input  wire             clk,
  input  wire             rst_n,
  input  wire             load,
  input  wire [WIDTH-1:0] data_in,
  input  wire             en,
  output reg  [WIDTH-1:0] count,
  output wire             overflow
);

  assign overflow = (count == {WIDTH{1'b1}});

  always @(posedge clk or negedge rst_n) begin
    if (!rst_n)
      count <= {WIDTH{1'b0}};
    else if (load)
      count <= data_in;
    else if (en)
      count <= count + 1'b1;
  end

endmodule
