/*///////////////////////////////////////////////////////////////////////////////////////////////////////////////
Execute Stage

Execute stage consists of ALU 
Executes the incoming instructions and performs computations on them

////////////////////////////////////////////////////////////////////////////////////////////////////////////////*/

`include "control.vh"
`include "functions.vh"

module execute (
    clock,
	pc_in,
	insn_in,
    insn_out,
    rs_data_in,
    rt_data_in,
    rt_data_out,
	rd_in,
    rd_out,
    control_in,
    control_out,
    branch_taken,
	result_data
);

	// inputs
    input wire clock;
    input wire[0:31] rs_data_in;
    input wire[0:31] rt_data_in;
    input wire[0:31] pc_in;
	input wire[0:31] insn_in;
    input wire[0:4]  rd_in;
	input wire[0:`CONTROL_BITS-1] control_in;

	
	// outputs
	output reg[0:31] insn_out;
	output reg[0:4] rd_out;
	output reg[0:31] rt_data_out;
    output reg[0:31] result_data;
    output reg 	branch_taken; 
	output reg[0:`CONTROL_BITS-1] control_out;
	
	
	wire[0:5] opcode;
	wire[0:4]  rt;
    wire[0:5] functn;
    wire[0:5] shift_amount;
	wire[0:15] offset;
    wire[0:15] immediate;
    wire[0:25] insn_index;
   
    
    assign opcode = insn_in[0:5];
    assign rt = insn_in[11:15];
	assign functn = insn_in[26:31];	
    assign shift_amount = insn_in[21:25];
	assign offset = insn_in[16:31];
    assign immediate = insn_in[16:31];
    assign insn_index = insn_in[6:31];


	always @(posedge clock) begin
	  // reset the control signals in case of NOP instructions for pipeline stalls
	    if (insn_in == 0) begin
            control_out[`I_TYPE] <= 1'b0;
            control_out[`R_TYPE] <= 1'b0;
            control_out[`J_TYPE] <= 1'b0;
            control_out[`MEM_WE] <= 1'b0;
			control_out[`REG_WE] <= 1'b0;
			control_out[`MEM_READ] <= 1'b0;
            control_out[`MEM_WB] <= 1'b0;
            control_out[`LINK] <= 1'b0;
			control_out[`ACCESS_SIZE_b1] = 1'b1;			// default access size set to 4 bytes (32 bits)
			control_out[`ACCESS_SIZE_b2] = 1'b1;
	    end else begin
              control_out <= control_in;
	  end
    end

    always @(posedge clock) begin
		$display("time: %d, PC_EXECUTE = %h, control_in = %b, instruction = %b", $time, pc_in, control_in, insn_in);
		
	    branch_taken = 0;          
	    if (control_in[`R_TYPE]) begin
			if (opcode == 6'b011100) begin
				result_data = $signed(rs_data_in) * $signed(rt_data_in);
				$display("time: %d, ALU: MUL (%d , %d)  Result = %d", $time, rs_data_in, rt_data_in, result_data); 
			end
	        case(functn)
	            `ADD: begin  //... rd <- rs + rt
					// If the addition results in 32-bit 2’s complement arithmetic overﬂow, the 
					// destination register is not modiﬁed and an Integer Overﬂow exception occurs.
					result_data = $signed(rs_data_in) + $signed(rt_data_in);
					if ( 
							( $signed(rs_data_in) > 0 && $signed(rt_data_in) > 0 && $signed(result_data) < 0 ) ||
							( $signed(rs_data_in) < 0 && $signed(rt_data_in) < 0 && $signed(result_data) > 0 )
						)	begin
					    $display("OVERFLOW EXCEPTION"); // target register should not be modified
					end	 
						$display("time: %d, ALU: ADD (%d , %d)  Result = %d", $time, rs_data_in, rt_data_in, result_data); 
				end	
	            `ADDU: begin  // also move insn 
					// no overflow exception under any circumstances
					result_data = $signed(rs_data_in) + $signed(rt_data_in);
					$display("time: %d, ALU: ADDU/MOVE (%d , %d)  Result = %d", $time, rs_data_in, rt_data_in, result_data); 
				end  
	            `SUB: begin
					// If the addition results in 32-bit 2’s complement arithmetic overﬂow, the 
					// destination register is not modiﬁed and an Integer Overﬂow exception occurs.
					result_data = $signed(rs_data_in) - $signed(rt_data_in);
					if ( 
							( $signed(rs_data_in) > 0 && $signed(rt_data_in) > 0 && $signed(result_data) < 0 ) ||
							( $signed(rs_data_in) < 0 && $signed(rt_data_in) < 0 && $signed(result_data) > 0 )
						)	begin
					    $display("OVERFLOW EXCEPTION"); // target register should not be modified
					end	
						$display("time: %d, ALU: SUB (%d , %d)  Result = %d", $time, rs_data_in, rt_data_in, result_data); 
				end  
	            `SUBU: begin
					  // no overflow exception under any circumstances
					  result_data = $signed(rs_data_in) - $signed(rt_data_in);
					  $display("time: %d, ALU: SUBU (%d , %d)  Result = %d", $time, rs_data_in, rt_data_in, result_data);
				end  
	            `SLT: begin // rd <- 1 if rs < rt; else rd <- 0 ; no overflow
					if ($signed(rs_data_in) < $signed(rt_data_in)) begin
					    result_data = 32'h00000001;
					end else begin
					    result_data = 32'h00000000;
					end
					$display("time: %d, ALU: SLT (%d , %d)  Result = %d", $time, rs_data_in, rt_data_in, result_data);  
				end  
	            `SLTU: begin // comparison as unsigned integers, no overflow
					if ($unsigned(rs_data_in) < $unsigned(rt_data_in)) begin
						result_data = 32'h0000001;
					end else begin 
						result_data = 32'h00000000; 
					end
					$display("time: %d, ALU: SLTU (%d , %d)  Result = %d", $time, $unsigned(rs_data_in), $unsigned(rt_data_in), result_data);    
				end  
	            `SLL: begin
	                result_data = rt_data_in << $unsigned(shift_amount);
				    $display("time: %d, ALU: SLL/NOP (%b << %d)  Result = %b", $time, rt_data_in, shift_amount, result_data);
				end
				`SRL: begin  // MUL
					if (opcode != 6'b011100) begin
						//result_data = rt_data_in >> $unsigned(shift_amount);
						result_data = rt_data_in >> shift_amount;
						$display("time: %d, ALU: SRL (%b >> %d)  Result = %b", $time, rt_data_in, shift_amount, result_data);
					end	
				 end 
				`SRA: begin
	                //result_data = rt_data_in >>> $unsigned(shift_amount);
					result_data = rt_data_in >>> shift_amount;
				    $display("time: %d, ALU: SRA (%b >>> %d)  Result = %b", $time, rt_data_in, shift_amount, result_data);
				end  
				`OR: begin
					result_data = rs_data_in | rt_data_in;
					$display("time: %d, ALU: OR (%b , %b)  Result = %b", $time, rs_data_in, rt_data_in, result_data);   
				end  
				`NOR: begin
					result_data = ~(rs_data_in | rt_data_in);
					$display("time: %d, ALU: NOR (%b , %b)  Result = %b", $time, rs_data_in, rt_data_in, result_data);  
				end 
	            `XOR: begin
					result_data = rs_data_in ^ rt_data_in;
					$display("time: %d, ALU: XOR (%b , %b)  Result = %b", $time, rs_data_in, rt_data_in, result_data);  
				end  	
	            `AND: begin
					result_data = rs_data_in & rt_data_in;
					$display("time: %d, ALU: AND (%b , %b)  Result = %b", $time, rs_data_in, rt_data_in, result_data);  
				end  
				`JR: begin
					result_data = rs_data_in;
					branch_taken = 1'b1;
					$display("time: %d, ALU: Branch Taken", $time);
					$display("time: %d, ALU: JR , Result rs_data = %h", $time, result_data);  
				 end
			endcase 
	    end else if(control_in[`I_TYPE]) begin
	        case(opcode)
	            `ADDIU: begin // also LI
					result_data = $signed(rs_data_in) + $signed(immediate); 
					$display("time: %d, ALU: ADDIU/LI (%d , %d)  Result = %d", $time, rs_data_in, $signed(immediate), $signed(result_data));  
				end  
	            `SLTI: begin
					if ($signed(rs_data_in) < $signed(immediate)) begin
						result_data = 32'h0000001;
					end else begin
						result_data = 32'h0000000;
					end
					$display("time: %d, ALU: SLTI (%d , %d)  Result = %d", $time, $signed(rs_data_in), $signed(immediate), result_data);  
				end   
	            `LW: begin
					result_data = $signed(offset) + rs_data_in;
					$display("time: %d, ALU: LW (offset = %h , base = %h)  Dest. Address = %h", $time, $signed(offset), $signed(rs_data_in), result_data);
				end 
				`LB: begin	// contents from main memory are sign extended
					result_data = $signed(offset) + rs_data_in;
					$display("time: %d, ALU: LB (offset = %h , base = %h)  Dest. Address = %h", $time, $signed(offset), $signed(rs_data_in), result_data);
				end  
				`LBU: begin  // contents from main memory are zero extended
					result_data = $signed(offset) + rs_data_in;
					$display("time: %d, ALU: LBU (offset = %h , base = %h)  Dest. Address = %h", $time, $signed(offset), $signed(rs_data_in), result_data);
				end  	
	            `SW: begin  // least significant 32 bits of register rt are stored in the memory
					result_data = $signed(offset) + rs_data_in;
					$display("time: %d, ALU: SW (offset = %h , base = %h)  Dest. Address = %h", $time, $signed(offset), $signed(rs_data_in), result_data);
				end  
				`SB: begin // least significant 8 bits of register rt are stored in the memory
					result_data = $signed(offset) + rs_data_in;
					$display("time: %d, ALU: SB (offset = %h , base = %h)  Dest. Address = %h", $time, $signed(offset), $signed(rs_data_in), result_data);
				end 
	            `LUI: begin
					result_data = immediate << 16;
					$display("time: %d, ALU: LUI (%b << 16 )  Dest. Address = %h", $time, immediate, result_data);
				end  
	            `ORI: begin
					result_data = rs_data_in | immediate;
					$display("time: %d, ALU: ORI (%b | %b )  Dest. Address = %h", $time, rs_data_in, immediate, result_data);
				end  
	        endcase
	    end else if (control_in[`J_TYPE]) begin
            case(opcode)
	            `J: begin                  
		            //result_data = ((pc_in + 4) & 32'hF0000000) | {(insn_index << 2), 2'b00}; 
					result_data = ((pc_in + 4) & 32'hfc00_0000) | (insn_index << 2); 
	                branch_taken= 1'b1;
					$display("time: %d, ALU: Branch Taken", $time);
					$display("time: %d, ALU: J (pc_in = %b , insn_index = %b), Dest. Address = %h", $time, pc_in, insn_index, result_data);
                end               
	            `JAL: begin
					//result_data = ((pc_in + 4) & 32'hF0000000) | {(insn_index << 2), 2'b00};
					result_data = ((pc_in + 4) & 32'hfc00_0000) | (insn_index << 2); 
					branch_taken= 1'b1;
					$display("time: %d, ALU: Branch Taken", $time);
					$display("time: %d, ALU: JAL (pc_in = %b , insn_index = %b), Dest. Address = %h", $time, pc_in, insn_index, result_data);
				end
	            `BEQ: begin
					if (rs_data_in == rt_data_in) begin
						//result_data = $signed(pc_in + 4) + $signed({(offset << 2), 2'b00});
						result_data = $signed(pc_in) + $signed(offset << 2);
						branch_taken= 1'b1;
						$display("time: %d, ALU: Branch Taken", $time);
					end else begin
						branch_taken= 1'b0;
						$display("time: %d, ALU: Branch NOT Taken", $time);
					end
					$display("time: %d, ALU: BEQ (pc_in = %b , offset = %b), Dest. Address = %h", $time, pc_in, offset, result_data);
				end  
	            `BNE: begin
					if  (rs_data_in != rt_data_in) begin
						//result_data = $signed(pc_in + 4) + $signed({(offset << 2), 2'b00});
						result_data = $signed(pc_in) + $signed(offset << 2);
						branch_taken = 1'b1;
						$display("time: %d, ALU: Branch Taken", $time);
					end else begin
						branch_taken = 1'b0;
						$display("time: %d, ALU: Branch NOT Taken", $time);
					end
					$display("time: %d, ALU: BNE (pc_in = %b , offset = %b), Dest. Address = %h", $time, pc_in, offset, result_data);
				end  
	            `BGTZ: begin
					if ($signed(rs_data_in) > 0) begin
						//result_data = $signed(pc_in + 4) + $signed({(offset << 2), 2'b00});
						result_data = $signed(pc_in) + $signed(offset << 2);
						branch_taken= 1'b1;
						$display("time: %d, ALU: Branch Taken", $time);
					end else begin
						branch_taken = 1'b0;
						$display("time: %d, ALU: Branch NOT Taken", $time);
					end
					$display("time: %d, ALU: BGTZ (pc_in = %b , offset = %b), Dest. Address = %h", $time, pc_in, offset, result_data);
				end  
	            `BLEZ: begin
					if ($signed(rs_data_in) <= 0) begin
						//result_data = $signed(pc_in + 4) + $signed({(offset << 2), 2'b00});
						result_data = $signed(pc_in) + $signed(offset << 2);
						branch_taken= 1'b1;
						$display("time: %d, ALU: Branch Taken", $time);
					end else begin
						branch_taken = 1'b0;
						$display("time: %d, ALU: Branch NOT Taken", $time);
					end
					$display("time: %d, ALU: BLEZ (pc_in = %b , offset = %b), Dest. Address = %h", $time, pc_in, offset, result_data);
				end 
	            `REGIMM:
		          case(rt)
		                `BLTZ: begin
							if ($signed(rs_data_in) < 0) begin
								//result_data = $signed(pc_in + 4) + $signed({(offset << 2), 2'b00});
								result_data = $signed(pc_in) + (offset << 2);
								branch_taken = 1'b1;
								$display("time: %d, ALU: Branch Taken", $time);
							end else begin
								branch_taken = 1'b0;
								$display("time: %d, ALU: Branch NOT Taken", $time);
							end
							$display("time: %d, ALU: BLTZ (pc_in = %b , offset = %b), Dest. Address = %h", $time, pc_in, offset, result_data);
						end		
		                `BGEZ: begin
							if ($signed(rs_data_in) >= 0) begin
								//result_data = $signed(pc_in + 4) + $signed({(offset << 2), 2'b00});
								result_data = $signed(pc_in) + $signed(offset << 2);
								branch_taken = 1'b1;
								$display("time: %d, ALU: Branch Taken", $time);
							end else begin
								branch_taken = 1'b0;
								$display("time: %d, ALU: Branch NOT Taken", $time);
							end
							$display("time: %d, ALU: BGEZ (pc_in = %b , offset = %b), Dest. Address = %h rs_data_in = %d", $time, pc_in, offset, result_data, $signed(rs_data_in));
					    end	
		          endcase 
	        endcase 
	    end else begin
			// NOP instruction
            result_data = 32'h0000_0000;
        end 
    end
    

    always @(posedge clock) begin
		insn_out = insn_in;
		rd_out = rd_in;
		
        if (opcode == `JAL) begin
    	   rt_data_out = (pc_in + 8);
        end else begin
           rt_data_out = rt_data_in;
        end
    end

/* Bypass logic for bonus marks

	// WX Bypass
	always @(posedge clock) begin
		if ( WE_writeBack_stage == 1 && rd_writeBack_stage != 0 && rs == rd_writeBack_stage) begin
			//Forward_rs = 10;
			rs_data_out = write_back_data;
		end else begin
			rs_data_out = rs_data;
		end 	
		if ( WE_writeBack_stage == 1 && rd_writeBack_stage != 0 && rt == rd_writeBack_stage) begin
			//Forward_rt = 10;
			rt_data_out = write_back_data;
		end else begin
			rt_data_out = rt_data;
		end 
	end	
	
	// MX bypass logic
	always @(posedge clock) begin
		if ( reg_wren_mem_stage == 1 && rd_mem_stage != 0 && rs == rd_mem_stage) begin
			rs_data_out = mem_stage_data_in;
		end else begin
			rs_data_out = rs_data;
		end 	
		if ( rd_mem_stage == 1 && rd_mem_stage != 0 && rt == rd_mem_stage) begin
			rt_data_out = mem_stage_data_in;
		end else begin
			rt_data_out = rt_data;
		end 
	end	
*/    

endmodule
