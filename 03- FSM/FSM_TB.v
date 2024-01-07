module FSM_TB ;
  reg clk , x , rst  ;
  wire y;
  wire res;  
  FSM TB (x , clk , rst , y);
  initial
  begin
       rst = 1 ;
       #100 rst = 0 ; x = 1 ;
       #100 x = 0 ;
       #100 x = 1 ;
       
  end
endmodule
