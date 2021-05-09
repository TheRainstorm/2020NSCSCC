`include "defines.vh"

module exception(
   input rst,
   input wire trap,
   input int, ri, break, syscall, overflow, addrErrorSw, addrErrorLw, pcError, eretM,
      //tlb exception
   input wire mem_read_enM,
   input wire mem_write_enM,
   input wire inst_tlb_refill,
   input wire inst_tlb_invalid,
   input wire data_tlb_refill,
   input wire data_tlb_invalid,
   input wire data_tlb_modify,

   input [31:0] cp0_status, cp0_cause, cp0_epc, cp0_ebase,
   input [31:0] pcM,
   input [31:0] mem_addrM,

   output [4:0] except_type,     //异常类型（同Cause CP0寄存器中的编码）
   output flush_exception,
   output [31:0] pc_exception,
   output [31:0] badvaddrM
);


   //TLB
   wire tlb_mod, tlb_tlbl, tlb_tlbs;
   assign tlb_mod = data_tlb_modify;
   assign tlb_tlbl = inst_tlb_refill | inst_tlb_invalid | mem_read_enM & (data_tlb_refill | data_tlb_invalid);
   assign tlb_tlbs = mem_write_enM & (data_tlb_refill | data_tlb_invalid);

   assign except_type =    (int)                   ? `EXC_CODE_INT   :

                           pcError                 ? `EXC_CODE_ADEL  :
                           inst_tlb_refill | inst_tlb_invalid ? `EXC_CODE_TLBL :

                           //CpU exception
                           (ri)                    ? `EXC_CODE_RI    :

                           (overflow)              ? `EXC_CODE_OV    :
                           (trap)                  ? `EXC_CODE_TR    :
                           (syscall)               ? `EXC_CODE_SYS   :
                           (break)                 ? `EXC_CODE_BP    :

                           addrErrorLw             ? `EXC_CODE_ADEL  :
                           (addrErrorSw)           ? `EXC_CODE_ADES  :
                           mem_read_enM & (data_tlb_refill | data_tlb_invalid) ? `EXC_CODE_TLBL :
                           mem_write_enM & (data_tlb_refill | data_tlb_invalid)? `EXC_CODE_TLBS :
                           data_tlb_modify ? `EXC_CODE_MOD :

                           (eretM)                 ? `EXC_CODE_ERET  :
                                                     `EXC_CODE_NOEXC;

   wire BEV;
   assign BEV = cp0_status[`BEV_BIT];

   wire tlb_refill;
   assign tlb_refill = inst_tlb_refill | data_tlb_refill;

   wire [31:0] base, offset;

   assign base   = BEV ? 32'hbfc0_0200 : cp0_ebase;
   assign offset = tlb_refill ? 32'b0 : 32'h180;

   assign pc_exception = eretM ? cp0_epc : base + offset;

   assign flush_exception =  (int) | (addrErrorLw | pcError | addrErrorSw) | (tlb_mod | tlb_tlbl | tlb_tlbs) | (ri) | (break) | (overflow) | (trap) | (eretM) | (syscall);

   assign badvaddrM       =  (pcError | inst_tlb_invalid | inst_tlb_refill) ? pcM : mem_addrM;
   
endmodule
