`default_nettype none

//-- Blinking led (125 MHz clock -> ~1 Hz on LED0)
module main (
    input clk,
    output wire [3:0] leds
);

  //-- 27-bit counter
  reg [26:0] counter;
  always @(posedge clk) begin
    counter <= counter + 1;
  end

  //-- Show the counter MSB on LED0
  assign leds[0]   = counter[26];

  assign leds[3:1] = 0;

  //-- Zynq processing-system block. Its ports are all tied off; it only
  //-- needs to exist so the bitstream configures the PS-PL interface.
`ifdef SYNTHESIZE
  ps7_stub ps7 (.clk(clk));
`endif

  //-- This is for simulation
  //-- the counter should start in 0
  initial begin
    counter = 0;
  end

endmodule
