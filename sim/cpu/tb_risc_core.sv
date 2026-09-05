`timescale 1ns/1ps
module tb_risc_core;
    logic clk=0, reset;
    wire [31:0] instruction_address,data_address,data_write_data;
    wire [3:0] data_byte_enable;
    wire data_write_enable;
    logic [31:0] instruction,data_read_data;
    wire illegal_instruction,instruction_address_misaligned,data_address_misaligned,halted;
    logic [31:0] imem[0:255];
    logic [31:0] dmem[0:255];
    integer i,errors=0,cycles;

    always #5 clk=~clk;
    always_comb begin
        instruction = imem[instruction_address[9:2]];
        data_read_data = dmem[data_address[9:2]];
    end
    always_ff @(posedge clk) if(data_write_enable) begin
        if(data_byte_enable[0]) dmem[data_address[9:2]][7:0]   <= data_write_data[7:0];
        if(data_byte_enable[1]) dmem[data_address[9:2]][15:8]  <= data_write_data[15:8];
        if(data_byte_enable[2]) dmem[data_address[9:2]][23:16] <= data_write_data[23:16];
        if(data_byte_enable[3]) dmem[data_address[9:2]][31:24] <= data_write_data[31:24];
    end

    risc_core dut(.*);

    function automatic [31:0] r(input [6:0] f7,input [4:0] rs2,rs1,input [2:0] f3,input [4:0] rd);
        r={f7,rs2,rs1,f3,rd,7'b0110011};
    endfunction
    function automatic [31:0] ii(input integer imm,input [4:0] rs1,input [2:0] f3,input [4:0] rd,input [6:0] op);
        ii={imm[11:0],rs1,f3,rd,op};
    endfunction
    function automatic [31:0] s(input integer imm,input [4:0] rs2,rs1,input [2:0] f3);
        s={imm[11:5],rs2,rs1,f3,imm[4:0],7'b0100011};
    endfunction
    function automatic [31:0] b(input integer imm,input [4:0] rs2,rs1,input [2:0] f3);
        b={imm[12],imm[10:5],rs2,rs1,f3,imm[4:1],imm[11],7'b1100011};
    endfunction
    function automatic [31:0] u(input [19:0] imm,input [4:0] rd,input [6:0] op);
        u={imm,rd,op};
    endfunction
    function automatic [31:0] j(input integer imm,input [4:0] rd);
        j={imm[20],imm[10:1],imm[11],imm[19:12],rd,7'b1101111};
    endfunction

    task automatic clear_mem;
        begin for(i=0;i<256;i++) begin imem[i]=32'b0; dmem[i]=32'b0; end end
    endtask
    task automatic pulse_reset;
        begin reset=1; repeat(2) @(posedge clk); #1; reset=0; end
    endtask
    task automatic wait_halt(input integer max_cycles);
        begin
            cycles=0;
            while(!halted && cycles<max_cycles) begin @(posedge clk); #1; cycles++; end
            if(!halted) begin $error("core did not halt within %0d cycles",max_cycles); errors++; end
        end
    endtask
    task automatic expect_reg(input integer n,input [31:0] value);
        begin if(dut.register_file_inst.registers[n]!==value) begin $error("x%0d=%h expected=%h",n,dut.register_file_inst.registers[n],value); errors++; end end
    endtask

    initial begin
        clear_mem(); reset=1;
        imem[0] =ii(64,0,3'b000,1,7'b0010011);       // addi x1,x0,64
        imem[1] =ii(-1,0,3'b000,2,7'b0010011);       // addi x2,x0,-1
        imem[2] =s(0,2,1,3'b000);                    // sb x2,0(x1)
        imem[3] =ii(0,1,3'b100,3,7'b0000011);        // lbu x3,0(x1)
        imem[4] =ii(0,1,3'b000,4,7'b0000011);        // lb x4,0(x1)
        imem[5] =ii(12'h123,0,3'b000,5,7'b0010011);  // addi x5,x0,0x123
        imem[6] =s(2,5,1,3'b001);                    // sh x5,2(x1)
        imem[7] =ii(2,1,3'b101,6,7'b0000011);        // lhu x6,2(x1)
        imem[8] =ii(2,1,3'b001,7,7'b0000011);        // lh x7,2(x1)
        imem[9] =s(4,6,1,3'b010);                    // sw x6,4(x1)
        imem[10]=ii(4,1,3'b010,8,7'b0000011);        // lw x8,4(x1)
        imem[11]=r(0,8,6,3'b000,9);                  // add x9,x6,x8
        imem[12]=r(7'b0100000,8,9,3'b000,10);        // sub x10,x9,x8
        imem[13]=ii(2,10,3'b001,11,7'b0010011);      // slli x11,x10,2
        imem[14]=ii(1,11,3'b101,12,7'b0010011);      // srli x12,x11,1
        imem[15]=ii(12'h404,2,3'b101,13,7'b0010011); // srai x13,x2,4
        imem[16]=r(0,1,2,3'b010,14);                 // slt x14,x2,x1
        imem[17]=r(0,1,2,3'b011,15);                 // sltu x15,x2,x1
        imem[18]=r(0,3,6,3'b100,16);                 // xor x16,x6,x3
        imem[19]=r(0,3,6,3'b110,17);                 // or x17,x6,x3
        imem[20]=r(0,3,6,3'b111,23);                 // and x23,x6,x3
        imem[21]=b(8,6,10,3'b000);                   // beq -> 92
        imem[22]=ii(1,0,3'b000,24,7'b0010011);       // skipped
        imem[23]=b(8,0,2,3'b001);                    // bne -> 100
        imem[24]=ii(1,0,3'b000,24,7'b0010011);       // skipped
        imem[25]=b(8,0,2,3'b100);                    // blt -> 108
        imem[26]=ii(1,0,3'b000,24,7'b0010011);       // skipped
        imem[27]=b(8,0,1,3'b101);                    // bge -> 116
        imem[28]=ii(1,0,3'b000,24,7'b0010011);       // skipped
        imem[29]=b(8,2,1,3'b110);                    // bltu -> 124
        imem[30]=ii(1,0,3'b000,24,7'b0010011);       // skipped
        imem[31]=b(8,1,2,3'b111);                    // bgeu -> 132
        imem[32]=ii(1,0,3'b000,24,7'b0010011);       // skipped
        imem[33]=u(20'h00000,18,7'b0010111);         // auipc x18,0 = 132
        imem[34]=u(20'h12345,19,7'b0110111);         // lui x19,0x12345
        imem[35]=j(8,20);                            // jal x20,148; link=144
        imem[36]=ii(1,0,3'b000,24,7'b0010011);       // skipped
        imem[37]=ii(160,0,3'b000,21,7'b0010011);     // addi x21,x0,160
        imem[38]=ii(0,21,3'b000,22,7'b1100111);      // jalr x22,0(x21); link=156
        imem[39]=ii(1,0,3'b000,24,7'b0010011);       // skipped
        imem[40]=s(8,9,1,3'b010);                    // completion store
        imem[41]=32'h00000000;                       // deliberate illegal halt
        pulse_reset(); wait_halt(80);
        if(!illegal_instruction || instruction_address!==32'd164) begin $error("unexpected final halt pc=%h illegal=%b",instruction_address,illegal_instruction); errors++; end
        expect_reg(0,0); expect_reg(3,255); expect_reg(4,32'hffff_ffff); expect_reg(6,32'h123);
        expect_reg(7,32'h123); expect_reg(8,32'h123); expect_reg(9,32'h246); expect_reg(10,32'h123);
        expect_reg(11,32'h48c); expect_reg(12,32'h246); expect_reg(13,32'hffff_ffff);
        expect_reg(14,1); expect_reg(15,0); expect_reg(16,32'h1dc); expect_reg(17,32'h1ff); expect_reg(23,32'h23);
        expect_reg(18,132); expect_reg(19,32'h12345000); expect_reg(20,144); expect_reg(22,156); expect_reg(24,0);
        if(dmem[16]!==32'h012300ff || dmem[17]!==32'h00000123 || dmem[18]!==32'h00000246) begin $error("memory image incorrect: %h %h %h",dmem[16],dmem[17],dmem[18]); errors++; end

        // Misaligned load must halt at the faulting PC and suppress writeback.
        clear_mem(); imem[0]=ii(65,0,3'b000,1,7'b0010011); imem[1]=ii(0,1,3'b010,2,7'b0000011);
        pulse_reset(); wait_halt(10);
        if(!data_address_misaligned || instruction_address!==4) begin $error("misaligned load behavior wrong"); errors++; end
        expect_reg(2,0);

        // Taken JAL to PC+2 must halt and suppress link-register writeback.
        clear_mem(); imem[0]=j(2,5); pulse_reset(); wait_halt(5);
        if(!instruction_address_misaligned || instruction_address!==0) begin $error("misaligned jump behavior wrong"); errors++; end
        expect_reg(5,0);

        if(!errors) $display("PASS: tb_risc_core"); else $fatal(1,"FAIL: tb_risc_core (%0d)",errors);
        $finish;
    end
endmodule
