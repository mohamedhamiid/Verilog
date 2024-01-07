module FSM(x,clk,rst,y);
input x , clk , rst;
output reg y ;

parameter A = 2'b00 , B = 2'b01 , C = 2'b10 , D = 2'b11 ;
reg[1:0] state , nextState ;

always @(posedge clk)
begin
  if(rst==1)
    state <= A ;
  else
    state <= nextState ;
end

always @(state,x)
begin
  case(state)
     A : 
          if(x)
            nextState = B ;
          else
            nextState = A ;
     B :
          if(x)
            nextState = B ;
          else
            nextState = C ;
     C :
          if(x)
            nextState = D ;
          else
            nextState = C ;
     D :
            nextState = A ;
  endcase
end


always@(state)
begin
  case(state)
     A : y = 0 ;
     B : y = 0 ;
     C : y = 0 ;
     D : y = 1 ;
  endcase
end

endmodule

