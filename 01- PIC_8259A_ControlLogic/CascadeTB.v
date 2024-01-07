module CascadeTB();

/* Master ANAS */
reg ICW1 , ICW2_4 ;

reg [7:0] Data ;


wire [7:0] eoi ;
wire [7:0] clr_ir;

wire ocld;
wire [7:0] CTRL_DATA;

reg ack;

reg [7:0] InINT;


/* Slave */
reg SICW1 , SICW2_4 ;

reg [7:0] SData ;

wire Socld;
wire [7:0] SCTRL_DATA;

reg [7:0] SInINT;

wire  [2:0] SLAVE_ID      ;

initial
begin
  /* ICW */
     ICW1 = 0 ; ICW2_4 = 0 ; InINT=0; ack=1;
     SICW1 = 0 ; SICW2_4 = 0 ; SInINT=0;

 #10 ICW1 = 1 ;  Data = 8'b00000001 ;
     SICW1 = 1 ;SData = 8'b00000001 ;
                  /* ICW1 */
 #10 ICW1 = 0 ; ICW2_4 = 1 ;Data = 8'b10101000 ;
     SICW1 = 0 ; SICW2_4 = 1 ;SData = 8'b10101000 ; /* ICW2 */
 
 #10 ICW2_4 = 0 ; 
     SICW2_4 = 0 ; 
 
 #10 ICW2_4 = 1 ;Data = 8'b00000100 ;
     SICW2_4 = 1 ;SData = 8'b00000010 ;            /* ICW3 */
 
 #10 ICW2_4 = 0; 
     SICW2_4 = 0;
 
 #10 ICW2_4 = 1 ;Data = 8'b00000011 ; 
     SICW2_4 = 1 ;SData = 8'b00000011 ;            /* ICW4 */
 
 #10 ICW2_4 = 0; 
     SICW2_4 = 0;
 /* Int */  
 #10 SInINT = 8'b00000010;
 /* Int */  
 #10 ack = 0;
 #10 ack=1;
 #10 ack = 0;
 #10 ack=1;
 
   
end


PIC_controlLogic picM(
    .internal_data_bus(Data),
    
    .write_ICW_1(ICW1)   ,
    .write_ICW_2_4(ICW2_4) ,

    .INTERRUPT(8'b0000000|SINT<<2),
    
    .EOI(eoi),
    
    .CLR_IR(clr_ir),
    .OUT_CTRL_LOGIC_DATA(ocld),
    .CTRL_LOGIC_DATA(CTRL_DATA),
    .INT(INT),
    .ACK(ack)    ,
    //.FREEZE(FREEZE),
    .SLAVE_ID(SLAVE_ID)            
);

PIC_controlLogic picS(
    .internal_data_bus(SData),
    
    .write_ICW_1(SICW1)   ,
    .write_ICW_2_4(SICW2_4) ,

    .INTERRUPT(SInINT),
    
    .OUT_CTRL_LOGIC_DATA(Socld),
    .CTRL_LOGIC_DATA(SCTRL_DATA),
    .INT(SINT),
    .cascade_in(SLAVE_ID)
);


endmodule

