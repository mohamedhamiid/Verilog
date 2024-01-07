module PIC_controlLogic(
    // Inputs from R/W logic
    input  [7:0] internal_data_bus,
    input   write_ICW_1   ,
    input   write_ICW_2_4 ,
    input   write_OCW_1   ,
    input   write_OCW_2   ,
    input   write_OCW_3   ,
    input   read          ,

    // CASCADE
    input   [2:0] cascade_in    ,
    output reg [2:0] SLAVE_ID   ,
    output reg  CASCADE_IO      ,
    
    // INPUTS FROM DETECTION LOGIC
    input   [7:0]   INTERRUPT   ,
    
    // Output from ICW1
    output reg  EDGE_OR_LEVEL ,          
    
    //OUTPUT OF OCW 1
    output reg [7:0]INT_MASK,  

    // OUTPUT FOR READ SIGNALL
    output  reg           EN_READ_REG,
    output  reg           READ_REG_ISR_OR_IRR,

    // OUT FOR INTERNAL BUS
    output reg OUT_CTRL_LOGIC_DATA     ,
    output reg [7:0] CTRL_LOGIC_DATA   ,
    
    // Output from Interrupt part
    output reg  LATCH  ,
    output reg  FREEZE ,

    output reg [7:0]   EOI             , 
    output reg [7:0]   CLR_IR          ,

    // INPUTS FROM PROCESSOR
    input ACK ,    
    
    // OUTPUT FROM CONTROL LOGIC
    output reg INT 

);
reg    EOI_SEQUENCE ;  
/**************************** USED FUNCTIONS *******************************/
function  [2:0] bit2num (input [7:0] source);
        if      (source[0] == 1'b1) bit2num = 3'b000;
        else if (source[1] == 1'b1) bit2num = 3'b001;
        else if (source[2] == 1'b1) bit2num = 3'b010;
        else if (source[3] == 1'b1) bit2num = 3'b011;
        else if (source[4] == 1'b1) bit2num = 3'b100;
        else if (source[5] == 1'b1) bit2num = 3'b101;
        else if (source[6] == 1'b1) bit2num = 3'b110;
        else if (source[7] == 1'b1) bit2num = 3'b111;
        else                        bit2num = 3'b111;
endfunction


 function  [7:0] num2bit (input [2:0] source);
        case (source)
            3'b000:  num2bit = 8'b00000001;
            3'b001:  num2bit = 8'b00000010;
            3'b010:  num2bit = 8'b00000100;
            3'b011:  num2bit = 8'b00001000;
            3'b100:  num2bit = 8'b00010000;
            3'b101:  num2bit = 8'b00100000;
            3'b110:  num2bit = 8'b01000000;
            3'b111:  num2bit = 8'b10000000;
            default: num2bit = 8'b00000000;
        endcase
    endfunction
    
/*
    THE CONTROL LOGIC IS DIVIDED FUNCTIONALLY INTO 2 PARTS:
          PART1 : INITIALIZION AND CONFIG
          PART2 : INTERRUPT HANDLING
*/    
    
/*============================ PART1 : INITIALIZION AND CONFIG =========================*/
/*================================= Variables Definition ===============================*/
/*------------------------------------- FSM STATES -------------------------------------*/
parameter CMD_READY  = 0 ;
parameter WRITE_ICW1 = 1 ; 
parameter WRITE_ICW2 = 2 ;
parameter WRITE_ICW3 = 3 ;
parameter WRITE_ICW4 = 4 ;

reg [2:0] command_state  ;
reg [2:0] next_command_state ; 

/*------------------------------------ REGISTERS BITS ----------------------------------*/
// 01- ICW1 Reg bits 
reg ICW1_B0_SET_ICW4;
reg ICW1_B1_SINGLE_OR_CASCADE;
reg ICW1_B2_CALL_ADDRESS_INTERVAL;
// 02- ICW2 Reg bits (FOR 8086) 
reg[4:0] ICW2_B3_7_VECTOR_ADDRES;
// 03- ICW3 Reg bits
reg[7:0] ICW3_CASCADE_CONFIG ;
// 04- ICW4 Reg bits
reg ICW4_B4_SPECIALLY_FULLY_NEST_CONFIG ;
reg ICW4_B1_AUTO_END_INTERRUPT;
reg ICW4_B0_PROCESSOR_MODE;

/*====================================== Function ======================================*/
/*---------------------------------------- FSM -----------------------------------------*/
 
always@(next_command_state) begin
          command_state <= next_command_state;
end
always@(posedge write_ICW_2_4,posedge write_ICW_1)begin
    if(write_ICW_1==1)
      next_command_state <= WRITE_ICW2 ;
    else if (write_ICW_2_4 == 1'b1) begin
          case(command_state)
              WRITE_ICW2: begin
                if (ICW1_B1_SINGLE_OR_CASCADE == 1'b0)begin
                    next_command_state <= WRITE_ICW3;
                  end
                else if (ICW1_B0_SET_ICW4 == 1'b1)begin
                    next_command_state <= WRITE_ICW4;
                  end
                else
                    next_command_state <= CMD_READY;
                end
              WRITE_ICW3: begin
                if (ICW1_B0_SET_ICW4 == 1'b1)
                    next_command_state <= WRITE_ICW4;
                else
                    next_command_state <= CMD_READY;
                end
              WRITE_ICW4: begin
                    next_command_state <= CMD_READY;
                end
              default: begin
                    next_command_state <= CMD_READY;
              end
           endcase
    end
    else
          next_command_state <= CMD_READY;
end

/*--------------------------------- DISTINGUISH ICW2_4 -------------------------------------*/
assign    write_ICW_2 = (command_state == WRITE_ICW2) & write_ICW_2_4;
assign    write_ICW_3 = (command_state == WRITE_ICW3) & write_ICW_2_4;
assign    write_ICW_4 = (command_state == WRITE_ICW4) & write_ICW_2_4;


/*--------------------------------- PARSING REGISTERS --------------------------------------*/
// ICW 1
/********************* ICW1_B0_SET_ICW4 ************************/
    always @(posedge write_ICW_1) begin
        if (write_ICW_1 == 1'b1)
            ICW1_B0_SET_ICW4 <= internal_data_bus[0];
        else
            ICW1_B0_SET_ICW4 <= ICW1_B0_SET_ICW4;
    end
/***************** ICW1_B1_SINGLE_OR_CASCADE *******************/
    always@(posedge write_ICW_1) begin
         if (write_ICW_1 == 1'b1)
            ICW1_B1_SINGLE_OR_CASCADE <= internal_data_bus[1];
        else
            ICW1_B1_SINGLE_OR_CASCADE <= ICW1_B1_SINGLE_OR_CASCADE;
    end
    
/************** ICW1_B2_CALL_ADDRESS_INTERVAL ******************/
    always@(posedge write_ICW_1) begin
        if (write_ICW_1 == 1'b1)
            ICW1_B2_CALL_ADDRESS_INTERVAL <= internal_data_bus[2];
        else
            ICW1_B2_CALL_ADDRESS_INTERVAL <= ICW1_B2_CALL_ADDRESS_INTERVAL;
    end
/************** ICW1_B3_LEVEL_OR_EDGE **************************/
    always@(posedge write_ICW_1) begin
        if (write_ICW_1 == 1'b1)
            EDGE_OR_LEVEL <= internal_data_bus[3];
        else
            EDGE_OR_LEVEL <= EDGE_OR_LEVEL;
    end

// ICW2
/************** ICW2_B3_7_VECTOR_ADDRES  ***********************/
  // T7-T3 (8086, 8088)
    always@(posedge write_ICW_2,posedge write_ICW_1) begin
        if (write_ICW_2 == 1'b1)
            ICW2_B3_7_VECTOR_ADDRES[4:0] <= internal_data_bus[7:3];
        else
            ICW2_B3_7_VECTOR_ADDRES[4:0] <= internal_data_bus[7:3];
    end 
// ICW3
// S7-S0 (MASTER) or ID2-ID0 (SLAVE)
/************* ICW3_CASCADE_CONFIG *****************************/
    always@(posedge write_ICW_3,posedge write_ICW_1) begin
         if (write_ICW_1 == 1'b1)
            ICW3_CASCADE_CONFIG <= 8'b00000000;
        else if (write_ICW_3 == 1'b1)
            ICW3_CASCADE_CONFIG <= internal_data_bus;
        else
            ICW3_CASCADE_CONFIG <= ICW3_CASCADE_CONFIG;
    end
// ICW4
/*********** ICW4_B1_AUTO_END_INTERRUPT ***********************/
    always@(posedge write_ICW_4,posedge write_ICW_1) begin
        if (write_ICW_1 == 1'b1)
            ICW4_B1_AUTO_END_INTERRUPT <= 1'b0;
        else if (write_ICW_4 == 1'b1)
            ICW4_B1_AUTO_END_INTERRUPT <= internal_data_bus[1];
        else
            ICW4_B1_AUTO_END_INTERRUPT <= ICW4_B1_AUTO_END_INTERRUPT;
    end
/*********** ICW4_B0_PROCESSOR_MODE ***************************/
    always@(posedge write_ICW_4 ,posedge write_ICW_1) begin
        if (write_ICW_1 == 1'b1)
            ICW4_B0_PROCESSOR_MODE <= 1'b0;
        else if (write_ICW_4 == 1'b1)
            ICW4_B0_PROCESSOR_MODE <= internal_data_bus[0];
        else
            ICW4_B0_PROCESSOR_MODE <= ICW4_B0_PROCESSOR_MODE;
    end   
    
// OCW1    
    always @(posedge write_OCW_1,posedge write_ICW_1) begin
        
       if (write_ICW_1 == 1'b1)
            INT_MASK <= 8'b11111111;
       else if ((write_OCW_1 == 1'b1) )
            INT_MASK <= internal_data_bus;
       else
            INT_MASK <= INT_MASK;
    end
// OCW2
   always @(posedge write_OCW_2,posedge write_ICW_1,posedge EOI_SEQUENCE) begin
        if (write_ICW_1 == 1'b1)
            EOI = 8'b11111111;
        else if ((ICW4_B1_AUTO_END_INTERRUPT == 1'b1) && (EOI_SEQUENCE == 1'b1))
            EOI = INTERRUPT;
        else if (write_OCW_2 == 1'b1) begin
            case (internal_data_bus[6:5])
                2'b11:   EOI = num2bit(internal_data_bus[2:0]);
                default: EOI = 8'b00000000;
            endcase
        end
        else
            EOI = 8'b00000000;
    end

    
    // RR/RIS
   always @(posedge write_OCW_3,posedge write_ICW_1) begin
        
         if (write_ICW_1 == 1'b1) begin
            EN_READ_REG     <= 1'b1;
            READ_REG_ISR_OR_IRR <= 1'b0;
        end
        else if (write_OCW_3 == 1'b1) begin
            EN_READ_REG     <= internal_data_bus[1];
            READ_REG_ISR_OR_IRR <= internal_data_bus[0];
        end
        else begin
            EN_READ_REG     <= EN_READ_REG;
            READ_REG_ISR_OR_IRR <= READ_REG_ISR_OR_IRR;
        end
    end
    
/*===============================================================================================*/    


/*================================== PART2 : INTERRUPT PART =====================================*/
/*==================================  Variables Definition ======================================*/
/*--------------------------- DISTINGUISH POS AND NEG EDGE OF THE ACK ---------------------------*/
    reg   PREV_ACK_n;
    reg    NEG_EDGE_ACK; 
    reg    POS_EDGE_ACK;
/*----------------------------------- INTERRUPT FSM STATES --------------------------------------*/
    parameter CTL_READY = 0 ;
    parameter ACK1 = 1 ; 
    parameter ACK2 = 2 ;
    
    reg [2:0]NEXT_CTL_STATE;
    reg [2:0]CTL_STATE;
/*----------------------------------------- CASCADE ----------------------------------------------*/
    reg CASCADE_MODE ;
    // SLAVE
    reg SLAVE_MATCH ;
     // MASTER  
    reg [7:0] INT_FROM_DEVICE;
    reg INT_FROM_SLAVE ;       // Chech that the source of interrupt is defined as slave
    
/*--------------------------------- INTERRUPT CONTROL SIGNALS ------------------------------------*/
    
    reg [2:0] IR        ; // DETERMINE THE OFFSET OF THE VECTOR ADDRESS FROM BASE
    
/*=======================================  FUNCTION ==============================================*/
/*--------------------------- DISTINGUISH POS AND NEG EDGE OF THE ACK ----------------------------*/
/*------------------------------------------ FSM -------------------------------------------------*/
    always@(ACK,posedge write_ICW_1) begin
        if (write_ICW_1==1)
            PREV_ACK_n <= 1'b1;
        else
            PREV_ACK_n <= ACK;
    end
    
    always@(ACK)begin
        NEG_EDGE_ACK =  PREV_ACK_n & ~ACK;
    end
    
    always@(ACK)begin
        POS_EDGE_ACK =  ~PREV_ACK_n & ACK;
    end
    
/*---------------------------------------- INTERRUPT FSM  -----------------------------------------*/
    always@(CTL_STATE) begin
        case (CTL_STATE)
            CTL_READY: begin
                    NEXT_CTL_STATE <= ACK1;
            end
            ACK1: begin
                    NEXT_CTL_STATE <= ACK2;
            end
            ACK2: begin
                    NEXT_CTL_STATE = CTL_READY;
            end
            default: begin
                    NEXT_CTL_STATE <= NEXT_CTL_STATE;
            end
        endcase
    end
    
    always@(negedge ACK , posedge write_ICW_1) begin
        if (write_ICW_1 == 1'b1)begin
            CTL_STATE <= CTL_READY;
            NEXT_CTL_STATE <= ACK1;
          end
        else
            CTL_STATE <= NEXT_CTL_STATE;
    end
/*---------------------------------------- CASCADE  -----------------------------------------*/    
    // Determine if cascade or not
    always@(*) begin
        if (ICW1_B1_SINGLE_OR_CASCADE == 1'b1)
            CASCADE_MODE = 1'b0;
        else
            CASCADE_MODE = 1'b1;
    end
    
    // SLAVE
    always@(cascade_in)begin
        if (ICW3_CASCADE_CONFIG[2:0] == cascade_in)
            SLAVE_MATCH = 1'b1;
    end  
    
    // MASTER 
    always@(posedge write_ICW_1,INTERRUPT)begin
      if(write_ICW_1==1)
          INT_FROM_DEVICE = 0;
      else if(CASCADE_MODE)
          INT_FROM_DEVICE = INTERRUPT;
      else
          INT_FROM_DEVICE = INT_FROM_DEVICE;
    end
    
    
    always@(INT_FROM_DEVICE,posedge write_ICW_1)begin
        if(write_ICW_1)
             INT_FROM_SLAVE = 0;
        else
          INT_FROM_SLAVE =(INT_FROM_DEVICE & ICW3_CASCADE_CONFIG) != 8'b00000000;
    end
    
    // Output slave id
    always@(CTL_STATE) begin
        if(CTL_STATE==ACK2)begin
            SLAVE_ID <= bit2num(INT_FROM_DEVICE);
            CASCADE_IO <= 1 ;
            
        end
    end
   
/*---------------------------------------- INTERRUPT CONTROL  -----------------------------------------*/
    // Interrupt control signals
    
    // AEOI SIGNAL     
    always@(CTL_STATE,NEXT_CTL_STATE)begin
       EOI_SEQUENCE =  ICW4_B1_AUTO_END_INTERRUPT & ((CTL_STATE != CTL_READY) & (NEXT_CTL_STATE == CTL_READY));

    end
        
    // INTERRUPT START AND END SIGNALS
    always@(posedge write_ICW_1,INTERRUPT,posedge EOI_SEQUENCE) begin
        if (write_ICW_1 == 1'b1)begin
            INT <= 1'b0;
            EOI_SEQUENCE = 0 ;  
          end
        else if (EOI_SEQUENCE == 1'b1)
            INT<= 1'b0;
        else if (INTERRUPT != 8'b00000000)begin
            INT <= 1'b1;
            IR = bit2num (INTERRUPT);
            
          end
        else
            INT <= INT;
    end
    
    // INTERRUPT VECTOR
    // MASTER
    always@(CTL_STATE)begin
        if (ACK == 1'b0) begin
            // Acknowledge
            case (CTL_STATE)
                CTL_READY: begin
                    if (CASCADE_MODE == 1'b0) begin
                            OUT_CTRL_LOGIC_DATA = 1'b0;
                            CTRL_LOGIC_DATA     = 8'b00000000;
                        end
                    else begin
                        OUT_CTRL_LOGIC_DATA = 1'b0;
                        CTRL_LOGIC_DATA     = 8'b00000000;
                    end
                end
                ACK1: begin
                        OUT_CTRL_LOGIC_DATA = 1'b0;
                        CTRL_LOGIC_DATA     = 8'b00000000;
                end
                ACK2: begin
                        OUT_CTRL_LOGIC_DATA = 1'b1;
                        CTRL_LOGIC_DATA     = ICW2_B3_7_VECTOR_ADDRES[4:0]+IR;                
                end
                
                default: begin
                    OUT_CTRL_LOGIC_DATA = 1'b0;
                    CTRL_LOGIC_DATA     = 8'b00000000;
                end
            endcase
        end
        else begin
            // Nothing
            OUT_CTRL_LOGIC_DATA = 1'b0;
            CTRL_LOGIC_DATA     = 8'b00000000;
        end
    end
    
    // SLAVE
     always@(posedge SLAVE_MATCH)begin
        OUT_CTRL_LOGIC_DATA = 1'b1;
        CTRL_LOGIC_DATA     = ICW2_B3_7_VECTOR_ADDRES[4:0]+IR;

    end  
/*---------------------------------------- LATCH  -----------------------------------------*/
    always@(*)begin
        if (write_ICW_1 == 1'b1)
            LATCH = 1'b0;
        else if (CASCADE_MODE == 1'b0)
            LATCH = (CTL_STATE == CTL_READY) & (NEXT_CTL_STATE != CTL_READY);
        else
            LATCH = (CTL_STATE == ACK2) & (SLAVE_MATCH == 1'b1) & (NEG_EDGE_ACK == 1'b1);
    end
    
/*---------------------------------------- FREEZE  -----------------------------------------*/
    always@(NEXT_CTL_STATE,posedge write_ICW_1,CTL_STATE,posedge POS_EDGE_ACK) begin
        if(write_ICW_1==1)
            FREEZE <= 1'b1;
        else if(CTL_STATE==ACK1)
            FREEZE <= 1'b0;
        else if (NEXT_CTL_STATE == CTL_READY&&POS_EDGE_ACK)
            FREEZE <= 1'b1;
        else
            FREEZE <= FREEZE;
    end
/*--------------------------------- CLEAR INTERRUPT REQUEST  --------------------------------*/
    always@(posedge write_ICW_1, negedge LATCH ,posedge NEG_EDGE_ACK)begin
        if (write_ICW_1 == 1'b1)
            CLR_IR = 8'b11111111;
         else if(NEXT_CTL_STATE == ACK1)
            CLR_IR = INTERRUPT;
        else if (LATCH == 1'b0)
            CLR_IR = 8'b00000000;
        else 
            CLR_IR = CLR_IR;
       
            
    end

endmodule