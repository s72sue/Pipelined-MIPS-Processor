/*///////////////////////////////////////////////////////////////////////////////////////////////////////////////
Fetch Module

Gets the PC and sends it to the memory and the decode module
Also, increments the PC after the execution of every instruction 

////////////////////////////////////////////////////////////////////////////////////////////////////////////////*/


module fetch(
		 clk_in,
         pc_mem_out,
         pc_decode_out,
		 wren_mem_out,
		 stall_in,
		 insn_in,
		 insn_decode_out,
		 jump_in,
		 pc_in,
		 access_size_out
);

    //Parameter Declarations
	parameter OFFSET = 32'h80020000;		//starting address of the main instruction memory
	parameter MEMORY_DEPTH = 1048576;		
	parameter ADDRESS_WIDTH = 32;

	//Input Ports
    input wire clk_in;
	input wire [0:ADDRESS_WIDTH-1] insn_in;   // instruction related to the pc, read from the main instruction memory
	input wire [0:ADDRESS_WIDTH-1] pc_in;	  // contains the address/PC of the instructions for doing branches 
	input wire jump_in;   		// if an instruction is a jump, then pc_in will be used
								//in order to read the next instruction which means a jump will be performed
	
	input wire stall_in;  		// used to insert a NOP. PC will not be 
								//incremented and even the data on the output lines doesn't change
	

	//Output Ports
	output reg [0:ADDRESS_WIDTH-1] pc_mem_out;     		// this contains the address to be supplied to the main instruction 
	reg [0:ADDRESS_WIDTH-1] pc_mem_o;			// memory for reading the actual instruction to be fetched from it
	
	output reg [0:ADDRESS_WIDTH-1] pc_decode_out;    	// this is used to transmit the pc to the decode stage
	reg [0:ADDRESS_WIDTH-1] pc_decode_o;
	output reg wren_mem_out ;							// indicates whether the fetch is reading/writing to the memory (always a read)
	output reg [0:1] access_size_out;					// fixed to 32 bits since always a full 32 bit instruction will be fetched 
	output wire [0:ADDRESS_WIDTH-1] insn_decode_out;	// used to transmit the instruction read from the main instruction memory to 

	//Internal Register Declaration
	reg [0:ADDRESS_WIDTH-1] pc;			// contains the address of the current instructions
	
	// insert a NOP instruction in the decode stage if the pipeline is stalled
	assign insn_decode_out = stall_in ? 32'h00000000 : insn_in;
	
	
	initial begin
	  $display ("Initialization of the fetch stage");
	  wren_mem_out = 1'b0;						// fetch module always reads from the memory
	  pc = OFFSET;
	  access_size_out = 2'b11;					// access size is 32 bits - always word size for this stage
	end

	
	
    always @ (posedge clk_in) begin
		
	    if (stall_in != 1'b1) begin
			if (jump_in) begin
				$display("time: %d, FETCH: BEGIN: PC (jump) = %h", $time, pc_in);
				pc_mem_out <= pc_in;
				pc_decode_out <= pc_in;
				pc <= pc_in + 4 ;
			end	else begin
				$display("time: %d, FETCH: BEGIN: PC = %h", $time, pc);
				pc_mem_out <= pc;
				pc_decode_out <= pc;
				pc <= pc + 4 ;
			end	
		end	else begin
			$display("time: %d, Stalled FETCH: BEGIN: insn_decode_out = %h", $time, insn_decode_out);
			$display("Stalling in FETCH: pc = %h, time = %d", pc, $time);
		end	
	end
	
	always @ (negedge clk_in)
	begin
	//#4
	$display("time: %d, FETCH: END: Instruction = %h,  insn_to_decode = %h", $time, insn_in, insn_decode_out);
	end

endmodule