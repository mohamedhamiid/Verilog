module PIC_controlLogic_TB();

reg ICW1 , ICW2_4 ;
reg OCW1 , OCW2 , OCW3  ;
wire LevelOrEdge ;
wire [7:0] Mask ;
reg [7:0] Data ;
//wire LATCH ;
//wire Freeze;
wire [7:0] eoi ;
wire [7:0] clr_ir;
wire OUT_FLAG_FROM_CTRL;
wire [7:0] CTRL_DATA;
reg ack;
wire EN_READ_REG;
wire READ_REG_ISR_OR_IRR;
reg [7:0] InINT;
initial
begin
  /* ICW */
     ICW1 = 0 ; ICW2_4 = 0 ; InINT=0; ack=1;
 #10 ICW1 = 1 ;Data = 8'b00001011 ;              /* ICW1 */
 #10 ICW1 = 0 ; ICW2_4 = 1 ;Data = 8'b10101000 ; /* ICW2 */
 #10 ICW2_4 = 0;
 #10 ICW2_4 = 1 ;Data = 8'b00000011 ;            /* ICW4 */
 
 
 /* OCW */
    OCW1 = 0 ; 
   #10 OCW1 = 1 ; Data = 8'b00000000 ; /* OCW1 */
   #10 OCW1 = 0 ; OCW2 = 1 ;Data = 8'b00000000 ; /* OCW2 */
   #10 OCW2 = 0 ; OCW3 = 1 ; Data = 8'b00000000 ;  /* OCW3 */
   #10 OCW3 = 0 ;
   
 /* Int */  
 #10 InINT = 8'b00000010;
 #10 ack = 0;
 #10 ack=1;
 #10 ack = 0;
 #10 ack=1;
   
   

end

PIC_controlLogic pic(
    .internal_data_bus(Data),
    
    .write_ICW_1(ICW1)   ,
    .write_ICW_2_4(ICW2_4) ,
    .write_OCW_1(OCW1)   ,
    .write_OCW_2(OCW2)   ,
    .write_OCW_3(OCW3)  ,
    .EDGE_OR_LEVEL(LevelOrEdge)     ,           
    .INT_MASK(Mask)  ,
    .INTERRUPT(InINT),
    //.LATCH(LATCH),
    //.FREEZE(Freeze),
    .EOI(eoi),
    .CLR_IR(clr_ir),
    .OUT_CTRL_LOGIC_DATA(OUT_FLAG_FROM_CTRL),
    .CTRL_LOGIC_DATA(CTRL_DATA),
    .INT(INT),
    .ACK(ack),
    .EN_READ_REG(EN_READ_REG),
    .READ_REG_ISR_OR_IRR(READ_REG_ISR_OR_IRR)
                     
);


endmodule