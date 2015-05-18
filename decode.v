/*///////////////////////////////////////////////////////////////////////////////////////////////////////////////
Decode Module

Receives instruction from the memory and decodes it
Receives PC from the fetch module as an input
Implements the stalling logic

////////////////////////////////////////////////////////////////////////////////////////////////////////////////*/

`include "control.vh"
`include "functions.vh"

module decode (
    clock,
	control_out,
    insn_in,
	ir_out,
    pc_in,
	pc_out,
    rs_data_out,
    rt_data_out,
    rdIn,
	rd_out,
    rd_alu_stage,
    rd_mem_stage,
	rd_writeBack_stage,
    write_back_data,
    reg_wren,
	reg_wren_alu_stage,
    reg_wren_mem_stage,
    WE_writeBack_stage,
    alu_branch_taken,
	stall_out,
    display_regs,
	reads_done
);

	// Inputs 
	input wire clock;
	input wire [0:31] pc_in;
    input wire[0:31] insn_in;
	input wire[0:4] rdIn;
	input wire[0:4] rd_alu_stage;
    input wire[0:4] rd_mem_stage;
    input wire[0:4] rd_writeBack_stage;
	input wire reg_wren_alu_stage;
    input wire reg_wren_mem_stage;
    input wire WE_writeBack_stage;
	input wire reg_wren;
	input wire[0:31]  write_back_data;
	input wire alu_branch_taken;
	input wire display_regs;
	input wire reads_done;
    
    
	// Outputs
	output wire[0:31] rs_data_out;
    output wire[0:31] rt_data_out;
	output reg[0:4] rd_out;
	output reg[0:31] pc_out; 
    output reg[0:31] ir_out;       
    output reg stall_out; 
	output reg[0:`CONTROL_BITS-1] control_out;  
	
	
    wire[0:31] insn; 
	wire[0:5] opcode;
	reg [0:31] NOP_insn;
    reg[0:31] stalled_insn;
	wire[0:4] rs;
    wire[0:4] rt;
    wire[0:4] rd;
    wire[0:5] functn;
    wire[0:4] shift_amount;
    wire[0:15] offset;
	wire[0:15] immediate;
    wire[0:25] jump_address;
	wire rs_stall; 
    wire rt_stall; 
	wire[0:31] rs_data; 
    wire[0:31] rt_data;
    

    assign insn = stall_out ? stalled_insn : insn_in;
	//assign insn = insn_in;
    assign opcode = insn[0:5];
    assign rs = insn[6:10];
    assign rt = insn[11:15];
    assign rd = insn[16:20];
    assign shift_amount = insn[20:25];
    assign functn = insn[26:31];
	assign offset = insn[16:31];
    assign immediate = insn[16:31];
    assign jump_address = insn[6:31];
	
    

    assign rs_stall = (
						((reg_wren_alu_stage == 1) && (rs == rd_alu_stage)) || 
						((reg_wren_mem_stage == 1) && (rs == rd_mem_stage)) ||
                        ((WE_writeBack_stage == 1) &&(rs == rd_writeBack_stage)) 
					  );

    assign rt_stall = (
						((reg_wren_alu_stage == 1) && (rt == rd_alu_stage)) || 
                        ((reg_wren_mem_stage == 1) && (rt == rd_mem_stage)) ||
                        ((WE_writeBack_stage == 1) && (rt == rd_writeBack_stage)) 
					  );   

	assign rs_data_out = rs_data;
    assign rt_data_out = rt_data;
   
   
	// Instantiating the register file
    register_file RF1(
        .clk (clock),
        .rsOut (rs_data),
        .rtOut (rt_data),
        .rsIn (rs),
        .rtIn (rt),
        .rdIn (rdIn),
        .reg_wren (reg_wren),
        .writeBack_data (write_back_data),
        .display_regs(display_regs)
    );

	
	
	initial begin
        NOP_insn = 32'h00000000;
		stall_out = 0;
    end

    always @(posedge clock) begin
        if (stall_out == 0) begin
			pc_out <= pc_in;
		end
		
	    stalled_insn <= insn;
    end

    always @(posedge clock) begin
	
		$display("time: %d, DECODE: PC = %h",  $time, pc_in);
		$display("time: %d, DECODE: rs = %d, rt = %d, rd = %d",  $time, rs, rt, rd);
		
		rd_out <= rd;
        control_out[`REG_WE] = 1'b0;
		control_out[`R_TYPE] = 1'b0;
        control_out[`I_TYPE] = 1'b0;
        control_out[`J_TYPE] = 1'b0;
		control_out[`MEM_READ] = 1'b0;
		control_out[`MEM_WB] = 1'b0;
        control_out[`MEM_WE] = 1'b0;
        control_out[`LINK] = 1'b0;
		control_out[`ACCESS_SIZE_b1] = 1'b1;			// default access size set to 4 bytes (32 bits)
		control_out[`ACCESS_SIZE_b2] = 1'b1;

	    
            case(opcode)
                // R type instructions
                6'b000000: begin
                    control_out[`R_TYPE] = 1'b1;
    	            if(functn == `JR) begin
    		            control_out[`REG_WE] = 0;
						$display("time: %d, DECODE: Insn Type: R-type: JR, Instruction = %b", $time, insn);
    	            end else begin
    		            control_out[`REG_WE] = 1;
						$display("time: %d, DECODE: Insn Type: R-type: (ADD, SUB, MOVE, NOP, SLL, ADDU, SUBU, SLT, SLTU, SRL, SRA, AND, OR, XOR, NOR, NOP), Instruction = %b", $time, insn);
    	            end
                end 
				
				// Multiply Instruction
				6'b011100: begin
					control_out[`R_TYPE] = 1'b1;
					control_out[`REG_WE] = 1;
					$display("time: %d, DECODE: Insn Type: R-type: MUL, Instruction = %b", $time, insn);
				end
           
                // I type instructions
                6'b001001: begin	 // ADDIU or LI
                    control_out[`I_TYPE] = 1'b1;
					control_out[`REG_WE] = 1'b1;
					rd_out <= rt;
					$display("time: %d, DECODE: Insn Type: I-type: ADDIU or LI, Instruction = %b", $time, insn);
                end
				`SW: begin 
					control_out[`I_TYPE] = 1'b1;
					control_out[`MEM_WE] = 1'b1;
                    control_out[`REG_WE] = 1'b0;
					rd_out <= rt;
					$display("time: %d, DECODE: Insn Type: I-type: SW, Instruction = %b", $time, insn);
                end
				`SB: begin 
					control_out[`I_TYPE] = 1'b1;
					control_out[`MEM_WE] = 1'b1;
                    control_out[`REG_WE] = 1'b0;
					control_out[`ACCESS_SIZE_b1] = 1'b0;
					control_out[`ACCESS_SIZE_b2] = 1'b1;
					rd_out <= rt;
					$display("time: %d, DECODE: Insn Type: I-type: SW, Instruction = %b", $time, insn);
                end
                `LW: begin 
				    control_out[`I_TYPE] = 1'b1;
                    control_out[`REG_WE] = 1'b1;
					control_out[`MEM_READ] = 1'b1;
                    control_out[`MEM_WB] = 1'b1;                    
					rd_out <= rt;
					$display("time: %d, DECODE: Insn Type: I-type: LW, Instruction = %b", $time, insn);
                end
				`LB: begin 
					control_out[`I_TYPE] = 1'b1;
					control_out[`MEM_READ] = 1'b1;
                    control_out[`REG_WE] = 1'b1;
                    control_out[`MEM_WB] = 1'b1;                    
					control_out[`ACCESS_SIZE_b1] = 1'b0;	
					control_out[`ACCESS_SIZE_b2] = 1'b1;
					rd_out <= rt;
					$display("time: %d, DECODE: Insn Type: I-type: LB, Instruction = %b", $time, insn);
                end
				`LBU: begin 
                    control_out[`REG_WE] = 1'b1;
                    control_out[`I_TYPE] = 1'b1;
                    control_out[`MEM_WB] = 1'b1;                    
                    control_out[`MEM_READ] = 1'b1;
					control_out[`ACCESS_SIZE_b1] = 1'b0;
					control_out[`ACCESS_SIZE_b2] = 1'b1;
					rd_out <= rt;
					$display("time: %d, DECODE: Insn Type: I-type: LBU, Instruction = %b", $time, insn);
                end
				`SLTI: begin 
					control_out[`I_TYPE] = 1'b1;
                    control_out[`REG_WE] = 1'b1;
					rd_out <= rt;
					$display("time: %d, DECODE: Insn Type: I-type: SLTI, Instruction = %b", $time, insn);
                end
                `LUI: begin 
					control_out[`I_TYPE] = 1'b1;
                    control_out[`REG_WE] = 1'b1;
					rd_out <= rt;
					$display("time: %d, DECODE: Insn Type: I-type: LUI, Instruction = %b", $time, insn);
                end
                `ORI: begin 
					control_out[`I_TYPE] = 1'b1;
                    control_out[`REG_WE] = 1'b1;
    	            //control_out[`LINK] = 1'b1;
					rd_out <= rt;
					$display("time: %d, DECODE: Insn Type: I-type: ORI, Instruction = %b", $time, insn);
                end
				
                 // J type instructions
				`REGIMM: begin // register immediate instructions
					control_out[`J_TYPE] = 1'b1;
                    control_out[`REG_WE] = 1'b0;
                    case(rt)
                        `BLTZ: begin
							$display("time: %d, DECODE: Insn Type: J-type: BLTZ, Instruction = %b", $time, insn);
						end
                        `BGEZ: begin
							$display("time: %d, DECODE: Insn Type: J-type: BGEZ, Instruction = %b", $time, insn); 
						end		
                        default:
                          $display("time: %d, DECODE: This REGIMM instruction is not implemented", $time);
                    endcase // case (rt)  
                end
				`BEQ: begin 
					control_out[`J_TYPE] = 1'b1;
                    control_out[`REG_WE] = 1'b0;
					$display("time: %d, DECODE: Insn Type: J-type: BEQ, Instruction = %b", $time, insn);
                end
                `BNE: begin 
					control_out[`J_TYPE] = 1'b1;
                    control_out[`REG_WE] = 1'b0;
					$display("time: %d, DECODE: Insn Type: J-type: BNE, Instruction = %b", $time, insn);
                end
                `BGTZ: begin 
					control_out[`J_TYPE] = 1'b1;
                    control_out[`REG_WE] = 1'b0;
					$display("time: %d, DECODE: Insn Type: J-type: BGTZ, Instruction = %b", $time, insn);
                end
                `BLEZ: begin 
				    control_out[`J_TYPE] = 1'b1;
                    control_out[`REG_WE] = 1'b0;
					$display("time: %d, DECODE: Insn Type: J-type: BLEZ, Instruction = %b", $time, insn);
                end
                `J: begin // unconditional jump
					control_out[`J_TYPE] = 1'b1;
                    control_out[`REG_WE] = 1'b0;
					$display("time: %d, DECODE: Insn Type: J-type: J, Instruction = %b", $time, insn);
                end
                `JAL: begin
					control_out[`J_TYPE] = 1'b1;
    	            control_out[`REG_WE] = 1'b1;
    	            control_out[`LINK] = 1'b1;
					rd_out <= 31;
					$display("time: %d, DECODE: Insn Type: J-type: JAL, Instruction = %b", $time, insn);
    	        end
                default:
                  $display("time: %d, DECODE: Instuction not implemented: %b", $time, insn);                  
            endcase 
    end 

	
	// decide what the outgoing instruction will be / STALL LOGIC for rs and rt
    always @(posedge clock) begin
		
		// flush the instruction in the pipeline if the branch is taken
		if (alu_branch_taken) begin
			$display("Branch Taken: Flushing the pipeline");
			control_out[`REG_WE] <= 0;
			rd_out <= 0;
			ir_out <= NOP_insn;
			//pc_out <= 32'hxxxxxxxx;
		//if its an invalid instruction, insert a NOP and flush the instruction in the pipeline
		end else if (insn == 32'h80000000 && reads_done == 1) begin
			stall_out = 1'b1;
			ir_out <= NOP_insn;	
			//pc_out <= 32'hxxxxxxxx;
		end else begin //if (stall_out == 1'b0) begin
			ir_out <= insn;
		end
	  	
		// instructions which use both rs and rt bits as operands/for calculation (6'b000000 -> R type instructions) ; 6'b011100 -> MUL	
		if (opcode == 6'b000000 || opcode == 6'b011100 || opcode == `SW || opcode == `SB || opcode == `BEQ || opcode == `BNE ) begin
			  if (rs_stall || rt_stall) begin
				  stall_out = 1'b1;
				  $display("Stalling in DECODE: rs_stall OR rt_stall, time = %d", $time);
				  rd_out <= 0;
				  ir_out <= NOP_insn;
				  //pc_out <= 32'hxxxxxxxx;
				  control_out[`REG_WE] <= 0;
				  if (opcode == `SW || opcode == `SB) begin
					  control_out[`MEM_WE] <= 0;
				  end
			  end else begin
				  stall_out = 1'b0;
			  end 
		end
		// instructions which use only rs as operand ( rt - destination or not used)
		// include immediate instructions which use only rs ( 6'b001001 -> ADDIU or LI )
		else if ( opcode == `REGIMM || opcode == `LW || opcode == `LB || opcode == `LBU  || opcode == `BLEZ || opcode == `BGTZ ||
				opcode ==  6'b001001 || opcode == `SLTI || opcode == `LUI || opcode == `ORI) begin
			if (rs_stall) begin
				stall_out = 1'b1;
				$display("Stalling in DECODE: rs_stall, time = %d", $time);
				rd_out <= 0;
				ir_out <= NOP_insn;
				//pc_out <= 32'hxxxxxxxx;
				control_out[`REG_WE] <= 0;
				if (opcode == `LW || opcode == `LB || opcode == `LBU) begin
					control_out[`MEM_WB] <= 1'b0;                    
					control_out[`MEM_READ] <= 1'b0;
				end
			end else begin
				stall_out = 1'b0;
			end
		end 
		// if none of the above instructions, don't stall the pipeline
		else begin
			 stall_out = 1'b0;
		end 
				
	end	
	
endmodule