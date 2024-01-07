module ALUTEST ;
  reg [31:0] A , B ;
  reg [3:0]  OP    ;
  
  wire [31:0] RES ;
  wire N , Z  ;  
  
  ALU TB_ALU (A , B , OP , RES , N , Z , C , V);
  
  initial
  begin
        A  =  1      ;
        B  =  2      ;
        
        // ADD
        OP = 4'b0000 ;
        // SUB
    #10 OP = 4'b0001 ;
        // OR
    #10 OP = 4'b0010 ;
        // AND
    #10 OP = 4'b0011 ;
        // NOR
    #10 OP = 4'b0100 ;
        // SLT
    #10 OP = 4'b0101 ;
  end
  
endmodule
