/*///////////////////////////////////////////////////////////////////////////////////////////////////////////////
Write Back Stage


////////////////////////////////////////////////////////////////////////////////////////////////////////////////*/

`include "control.vh"

module writeBack_stage (
	clk,
	memData_in,				//from the data memory (for load instructions)
	rdData_in,				//the computed value from the ALU (coming through the mem stage) to be written to the destination register  
	writeBackData,			//data to be written to the register file
	reg_wren,				//whether register can be written to	
	rd_in,  				//the destination register (5 bits) coming as input to the writeback stage				
	rd_out,					//the destination register (5 bits) an output from the writeback stage
	control_in                      
);

	
	input wire clk;
    input wire[0:4] rd_in;
    input wire[0:31] rdData_in;
    input wire[0:31] memData_in;
    input wire[0:`CONTROL_BITS - 1] control_in;
	
	output reg reg_wren;
	output reg[0:4] rd_out;
    output reg[0:31] writeBackData;
	
    always @(posedge clk) begin
		//$display("IN WRITEBACK STAGE, time = %d", $time);
		#3
		reg_wren <= control_in[`REG_WE]; 			
		if (control_in[`MEM_WB]) begin
			writeBackData <= memData_in;	// data from memory
		end 
		else begin	
			writeBackData <= rdData_in;		//data from the ALU
		end
		rd_out <= rd_in;
	end

endmodule	