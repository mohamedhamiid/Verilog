module ALU (OP1 , OP2 , OPCode , RES , PSR);
  input [31:0] OP1 , OP2 ;
  input [3:0]  OPCode    ;
  
  output reg signed [31:0] RES  ;
  output reg [1:0] PSR ;
  
  always@(RES)
    begin
      PSR[0] = (RES==0) ;
      PSR[1] = (RES <0) ; 
    end
  
  parameter ADD = 4'b0000 ;
  parameter SUB = 4'b0001 ;  
  parameter OR  = 4'b0010 ;
  parameter AND = 4'b0011 ;
  parameter NOR = 4'b0100 ;
  parameter SLT = 4'b0101 ;
  /*
        ALU
    0000 --> ADD
    0001 --> SUB
    0010 --> OR
    0011 --> AND
    0100 --> NOR
    0101 --> SLT
  
  */
  
  // Choose Operation
  always @(OPCode or OP1 or OP2)  
  case(OPCode)
    ADD : RES = OP1 + OP2       ;
    SUB : RES = OP1 - OP2       ;
    OR  : RES = OP1 | OP2       ;
    AND : RES = OP1 & OP2       ;
    NOR : RES = ~(OP1 | OP2)    ;
    SLT : RES = OP1<OP2         ;
  endcase
  
endmodule