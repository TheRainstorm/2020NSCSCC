`include "defines.vh"

module int(
    input [31:0] cp0_status, cp0_cause,

    output wire int
);
   //INTERUPT
   //             //IE             //EXL            
   assign int =   cp0_status[`IE_BIT] && ~cp0_status[`EXL_BIT] && (
                     //IM                 //IP
                  ( |(cp0_status[`IM1_IM0_BITS] & cp0_cause[`IP1_IP0_BITS]) ) ||        //soft interupt
                  ( |(cp0_status[`IM7_IM2_BITS] & cp0_cause[`IP7_IP2_BITS]) )           //hard interupt
   );
   // 全局中断开启,且没有例外在处理,识别软件中断或者硬件中断;
endmodule