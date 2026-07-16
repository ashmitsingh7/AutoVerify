// Seed content for the editor's "Example" button only. All analysis,
// validation, and generation output now comes from the real backend
// (see lib/services/*) — this file no longer holds any mock results.
export const EXAMPLE_VERILOG = `// counter.sv
module counter #(
    parameter WIDTH = 8
) (
    input  logic             clk,
    input  logic             rst_n,
    input  logic             en,
    input  logic             load,
    input  logic [WIDTH-1:0] load_val,
    output logic [WIDTH-1:0] count,
    output logic             overflow
);

    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            count    <= '0;
            overflow <= 1'b0;
        end else if (load) begin
            count    <= load_val;
            overflow <= 1'b0;
        end else if (en) begin
            {overflow, count} <= count + 1'b1;
        end
    end

endmodule
`
