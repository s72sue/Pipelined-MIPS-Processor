/*////////////////////////////////////////////////////////////////////////////////////////////////////////////////
Test Bench

- Interacts with the parser.v , main_memory.v, decode and execute stages
- Used to read data from the memory to verify the 
  functioning of the parser and the main main_memory.
-Implements the interfacing between the various pipeline stages  

srec_done = 0 => WRITE: parser is writing to the memory
srec_done = 1 => READ: parser is done writing, so reads can 
			 be performed now.

////////////////////////////////////////////////////////////////////////////////////////////////////////////////*/

`include "control.vh"
`include "functions.vh"

module test_bench();
    
	reg clk;

	// main instruction memory
	wire       write_en;
	reg        tb_write_en;
    wire[0:31] addr;
	reg[0:31]  tb_addr;
    wire[0:31] data_in;
	reg[0:31]  tb_data_in;
    wire[0:31] data_out;
	//wire[0:31] tb_data_out;
	

   
	// fetch module
	wire       fetch_write_en;
    wire[0:31] fetch_addr;
    wire[0:31] fetch_data_in;
    wire[0:31] fetch_data_out; 
    reg        fetch_stall;
	reg		   fetch_intial_stall;
	wire[0:31] fetch_insn_decode;
    wire[0:31] fetch_pc;
	
	
    wire[0:31]  fetch_pc_in;
    wire  fetch_jmp;
    reg[0:31]  fetch_pc_in_buff_0;
    reg  fetch_jmp_buff_0;
    reg[0:31]  fetch_pc_in_buff_1;
    reg  fetch_jmp_buff_1; 
	
	// srec parser module
	wire srec_par_done;		// whether srec parser is done parsing and writing to memory ( 0 -> before, 1 -> when done )
    wire[0:31] srec_addr;			// parsed address from the parser to be asserted to the main insn memory
    wire[0:31] srec_data_in;		// parsed data from the parser to be asserted to the main insn memory
    

	reg [0:31] mem_addr_in;		// for reading the addresses in the srec file from the main memory
	integer linenum = 0;		//  starting line number to read from the srec file
	integer linemax = 100;		// ending line number to read from the srec file
	reg read_done;				// when reads are done, fetching can be started
	
	
	// decode module
	 wire[0:31] decode_rs_data;
    wire[0:31] decode_rt_data;
    wire[0:4]  decode_rd_in;
    wire[0:31] decode_pc_out;
    wire[0:31] decode_ir_out;
    wire[0:31] decode_wb_data;
    wire       decode_reg_write_en;
    wire[0:`CONTROL_BITS-1] decode_ctrl;
    wire[0:4]  decode_rd_out;
    reg        decode_dump_regs; 
	wire 	   decode_stall_out;

	
	// execute module
	reg[0:31]  alu_rs_data_res;
    reg[0:31]  alu_rt_data_res;
    reg[0:31]  alu_insn;
    wire[0:31] alu_output;
    wire        alu_bt;
    wire[0:31] alu_rt_data_out;
    wire[0:31] alu_insn_out;
    reg [0:31] alu_pc_res;
    wire[0:`CONTROL_BITS-1] alu_ctrl_out;
    wire[0:4] alu_rd_in;
    wire[0:4] alu_rd_out;
	
	
	// data memory
	wire[0:31] mem_stage_addr;
    wire[0:31] mem_stage_data_in;
    wire[0:31] mem_stage_data_out;
    wire[0:`CONTROL_BITS-1] mem_stage_ctrl_in;
    wire[0:`CONTROL_BITS-1] mem_stage_ctrl_out;
    wire[0:31] mem_stage_insn;
    wire[0:31] mem_stage_insn_out;        
    wire[0:31] mem_stage_mem_data_out;
    wire[0:4] mem_stage_rd_in;
    wire[0:4] mem_stage_rd_out;
	reg[0:`CONTROL_BITS-1]  mem_stage_srec_read_ctrl;
	
	   
	// pipeline registers
	reg [0:31] decode_insn_in; 
	reg [0:31] decode_pc_in; 
	
	reg [0:31] execute_insn_in; 
	reg [0:31] execute_pc_in; 
	
	reg [0:31] DATAMEM_insn_in;
	reg [0:31] WB_insn_in;
	
	integer count;
	
	parser #("C:\\modelsim_intro\\New Folder\\SimpleAdd.srec") P1(
        .clk (clk),
        .mem_addr (srec_addr),
        .mem_data_in (srec_data_in),
        .done (srec_par_done)
    );
		
    main_memory INSN_MEM(
        .clk (clk), 
        .address (addr), 
        .write_enable (write_en), 
        .data_in (data_in), 
        .data_out (data_out),
		.access_size(2'b11)
    );
	
    fetch F1(
        .clk_in (clk), 
        .pc_mem_out (fetch_addr),
        .insn_in (fetch_data_in),
        .insn_decode_out (fetch_data_out),
        .pc_decode_out (fetch_pc),
        .write_en_mem_out (fetch_write_en),
        .stall_in (fetch_stall),
		.jump_in(fetch_jmp),
		.pc_in(fetch_pc_in),
		.access_size_out()
    );

	 decode D1(
        .clock (clk),
		.control_out (decode_ctrl),
        .insn_in (fetch_data_out),
        .pc_in (fetch_pc),
		.pc_out (decode_pc_out),
        .rs_data_out (decode_rs_data),
        .rt_data_out (decode_rt_data),
        .rdIn (decode_rd_in),
        .ir_out (decode_ir_out),
		.rd_out (decode_rd_out),
		.write_back_data (decode_wb_data),
        .reg_write_en (decode_reg_write_en),
		.rd_alu_stage(decode_rd_out),
		.rd_mem_stage(alu_rd_out),	
		.rd_writeBack_stage(mem_stage_rd_out),
		.reg_write_en_alu_stage(decode_ctrl[`REG_WE]),
		.reg_write_en_mem_stage(mem_stage_ctrl_in[`REG_WE]),
		.WE_writeBack_stage(mem_stage_ctrl_out[`REG_WE]),
		.alu_branch_taken(alu_bt),
		.stall_out(decode_stall_out),
        .display_regs (decode_dump_regs),
		.reads_done(read_done)
    );
	
	 execute EX1(
        .clock (clk),
		.pc_in (decode_pc_out),
		.insn_in (decode_ir_out),
        .insn_out(alu_insn_out),
        .rs_data_in (decode_rs_data),
        .rt_data_in (decode_rt_data),
		.rt_data_out(alu_rt_data_out),
		.rd_in (decode_rd_out),
	    .rd_out (alu_rd_out),
        .control_in (decode_ctrl),
        .control_out (alu_ctrl_out),
		.branch_taken (alu_bt),
        .result_data (alu_output)
    );
	
	 data_memory DATA_MEM(
        .clk (clk),
        .mem_address (mem_stage_addr),
        .mem_data_in (mem_stage_data_in),
		.rd_in (alu_rd_out),
		.control_in (mem_stage_ctrl_in),
		.mem_data_out (mem_stage_mem_data_out),
		.rd_data_out (mem_stage_data_out),
		.rd_out (mem_stage_rd_out),   
        .control_out (mem_stage_ctrl_out)   
    );
	
	writeBack_stage WB1(
        .clk (clk),
		.memData_in (mem_stage_mem_data_out),
		.rdData_in (mem_stage_data_out),
	    .writeBackData (decode_wb_data),
		.reg_write_en (decode_reg_write_en), 
        .rd_in (mem_stage_rd_out),
        .rd_out (decode_rd_in),
        .control_in (mem_stage_ctrl_out)
    );
 
	
	// pipeline registers	
	always @ (posedge clk) begin
	
		decode_insn_in <= fetch_data_out;
		decode_pc_in <= fetch_pc;
	
	end	
		 
	// data memory assignments
	assign mem_stage_addr = srec_par_done ? alu_output : srec_addr;
    assign mem_stage_data_in = srec_par_done ? alu_rt_data_out : srec_data_in;
    assign mem_stage_ctrl_in = srec_par_done ? alu_ctrl_out : mem_stage_srec_read_ctrl;
   
   // SREC PARSER:  
	// mux for selecting the address input to the memory
	always @ ( srec_par_done or mem_addr_in or srec_addr) begin
		if (srec_par_done == 1) begin
			tb_addr = mem_addr_in;
		end else begin
			tb_addr = srec_addr;
		end
	end	
	
	always @ ( read_done or decode_stall_out or fetch_stall) begin
		if (read_done == 1) begin
			fetch_stall = decode_stall_out;
			$display("FETCH stall = %d, time = %d", fetch_stall, $time);
		//end else begin
			//fetch_stall = fetch_stall;
		end
	end	
		
	
	// address and write_en going to the main memory
    assign addr = srec_par_done ? (fetch_stall ? tb_addr : fetch_addr) : tb_addr;
    assign write_en = srec_par_done ? (fetch_stall ? tb_write_en : fetch_write_en) : (!srec_par_done);
    //assign tb_data_out = data_out;
    assign fetch_data_in = data_out;
    assign data_in = srec_par_done ? (fetch_stall ? tb_data_in : fetch_data_in) : srec_data_in;

	
	assign fetch_pc_in = alu_output;
    assign fetch_jmp = alu_bt; 		
		
	initial begin
		$display("Starting the Simulation");
		// print the signal values whenever they change
		$monitor ("time: %d,\t\tclk_tb = %b,\t\t\twrite_enable = %b,\t\tmem_addr_line = %h,\t\tmem_datain_line = %h,\t\t\tmem_dataout_line = %h, \t\t\tpc_to_decode = %h", $time, clk, write_en, addr, srec_data_in, data_out, fetch_pc);
	end
	
	
    // Specify when to stop the simulation
    event terminate_sim;
    initial begin 
        @ (terminate_sim);
        #10 $finish;
    end
   
    initial begin
        clk = 1;
        fetch_stall = 1;
		read_done = 0;
		tb_write_en = 1'b0;
		mem_stage_srec_read_ctrl = 0;
        mem_stage_srec_read_ctrl[`MEM_WE] = 1;
		mem_stage_srec_read_ctrl[`ACCESS_SIZE_b1] = 1;
		mem_stage_srec_read_ctrl[`ACCESS_SIZE_b2] = 1;
		count = 0;
    end

	
    always begin
        #10 clk = !clk;
    end 
	
		
	// initiate the read at every rising edge
	// loop through all the files in the srec file to 
	// get the address where the data needs to be read from
	initial begin
		@ (posedge srec_par_done);
		if (srec_par_done == 1) begin
			$display();
			$display("///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////");	
			$display("///////////////////////////////////////////////////BEGINNING OF READS FROM THE MAIN MEMORY/////////////////////////////////////////////////////////////////");
			$display("///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////");
			$display();	
			while(linenum < linemax) begin
				@ (posedge clk);
				mem_addr_in <= 32'h80020000 + (32'h00000004 * linenum);
				linenum = linenum + 1;
			end
			read_done = 1;
		end
	end 
	
	
	initial begin
		@(posedge read_done);
		@(posedge clk);
		$display();
		$display("///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////");	
		$display("/////////////////////////////////////////////////// INITIAL STATE OF THE REGISTER FILE /////////////////////////////////////////////////////////////////");
		$display("///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////");
		$display();	
		decode_dump_regs = 1;
		@(posedge clk);
		decode_dump_regs = 0;
		@(posedge clk);
		if (read_done == 1) begin	
			fetch_stall = 0;
			$display();
			$display("///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////");	
			$display("///////////////////////////////////////////////////BEGINNING OF FETCHING AND DECODING INSTRUCTIONS/////////////////////////////////////////////////////////////////");
			$display("///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////");
			$display();	
		end	
	end
	
	
	// print the register file contents after the last JR instruction
    always @ (posedge clk) begin
		//decode_dump_regs = 1;
		if (alu_insn_out[26:31] == `JR && alu_output == 31) begin
				$display ("Terminating the program");
				@(posedge clk);
				$display();
				$display("///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////");	
				$display("/////////////////////////////////////////////////// FINAL STATE OF THE REGISTER FILE /////////////////////////////////////////////////////////////////");
				$display("///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////");
				$display();	
				decode_dump_regs = 1;
				@(posedge clk);
				decode_dump_regs = 0;
				@(posedge clk);
				-> terminate_sim;
		end
	end

endmodule