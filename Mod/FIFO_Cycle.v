module FIFO_Cycle
       #
       (
           parameter [31: 0]data_bit_width = 32'd12, //数据位宽
           parameter [31: 0]data_bit_depth = 32'd10, //数据位深
           parameter [31: 0]data_depth = 32'd1000 //数据深度
       )
       (
           input wr_clk,
           input rd_clk,
           input rst_n,

           input wr_en,
           input rd_en,

           input [data_bit_width - 1: 0]data_fifo_in,

           output reg [data_bit_width - 1: 0]data_fifo_out = 1'd0
       );

reg [data_bit_width - 1: 0]ram[(1 << data_bit_depth) - 1: 0];
reg [data_bit_depth - 1: 0]wr_addr = 1'd0;
reg [data_bit_depth - 1: 0]rd_addr = 1'd0;

always@(posedge wr_clk or negedge rst_n)
begin
    if(!rst_n)
    begin
        wr_addr<=1'd0;
    end
    else
    begin
        if(wr_en)
        begin
            ram[wr_addr]<=data_fifo_in;

            if(wr_addr<data_depth-1'd1)
            begin
                wr_addr<=wr_addr+1'd1;
            end
            else
            begin
                wr_addr<=1'd0;
            end
        end
    end
end

always@(posedge rd_clk or negedge rst_n)
begin
    if(!rst_n)
    begin
        rd_addr<=1'd0;
    end
    else
    begin
        if(rd_en)
        begin
            data_fifo_out<=ram[rd_addr];

            if (rd_addr < data_depth - 1'd1)
            begin
                rd_addr <= rd_addr + 1'd1;
            end
            else
            begin
                rd_addr<=1'd0;
            end
        end
    end
end

endmodule
