module bilinear_interpolation (
    input logic [15:0] x,   // Non-integer x-coordinate (fixed-point, 8.8)
    input logic [15:0] y,   // Non-integer y-coordinate (fixed-point, 8.8)
    input logic [7:0] a1,   // Top-right value
    input logic [7:0] a2,   // Top-left value
    input logic [7:0] a3,   // Bottom-right value
    input logic [7:0] a4,   // Bottom-left value
    output logic [7:0] v   // Interpolated value (fixed-point, 8.8)
);

    // Internal signals for fractional distances and intermediate results
    logic [7:0] dx, dy;             // Fractional distances (fixed-point, 0.8)
    logic [15:0] v1, v2;            // Intermediate results with extended precision

    // Compute fractional parts (dx = fractional part of x, dy = fractional part of y)
    assign dx = x[7:0]; // Lower 8 bits of x for fractional part
    assign dy = y[7:0]; // Lower 8 bits of y for fractional part

    // Top row interpolation: v1 = a1 * (1 - dx) + a3 * dx
    assign v1 = ((a1 * ((1 << 8) - dx)) + (a2 * dx)) >> 8;

    // Bottom row interpolation: v2 = a2 * (1 - dx) + a4 * dx
    assign v2 = ((a3 * ((1 << 8) - dx)) + (a4 * dx)) >> 8;

    // Final interpolation: v = v1 * (1 - dy) + v2 * dy
    assign v = ((v1 * ((1 << 8) - dy)) + (v2 * dy)) >> 8;

endmodule