module TopModule #(
    parameter WIDTH = 8,
    parameter DEPTH = 16
)(
    input wire wclk,
    input wire rclk,
    input wire wrstn,
    input wire rrstn,
    input wire winc,
    input wire rinc,
    input wire [WIDTH-1:0] wdata,
    output wire wfull,
    output wire rempty,
    output wire [WIDTH-1:0] rdata
);
    parameter ADDR_WIDTH = $clog2(DEPTH);
    localparam [ADDR_WIDTH:0] CAPACITY = DEPTH;
    // The supplied RAM declares a two-bit [-1:0] port at depth one.
    localparam RAM_ADDR_WIDTH = (DEPTH == 1) ? 2 : $clog2(DEPTH);

    reg [ADDR_WIDTH:0] waddr_bin, raddr_bin;
    reg [ADDR_WIDTH:0] wptr, rptr;
    (* ASYNC_REG = "TRUE" *) reg [ADDR_WIDTH:0] wptr_buff, wptr_syn;
    (* ASYNC_REG = "TRUE" *) reg [ADDR_WIDTH:0] rptr_buff, rptr_syn;

    wire wen = wrstn && winc && !wfull;
    wire ren = rrstn && rinc && !rempty;
    wire [ADDR_WIDTH:0] waddr_next = waddr_bin + 1'b1;
    wire [ADDR_WIDTH:0] raddr_next = raddr_bin + 1'b1;

    // Register Gray pointers before crossing domains. Each accepted transfer
    // advances its binary and Gray pointers on the same edge.
    always @(posedge wclk or negedge wrstn) begin
        if (!wrstn) begin
            waddr_bin <= 0;
            wptr <= 0;
        end else if (wen) begin
            waddr_bin <= waddr_next;
            wptr <= waddr_next ^ (waddr_next >> 1);
        end
    end

    always @(posedge rclk or negedge rrstn) begin
        if (!rrstn) begin
            raddr_bin <= 0;
            rptr <= 0;
        end else if (ren) begin
            raddr_bin <= raddr_next;
            rptr <= raddr_next ^ (raddr_next >> 1);
        end
    end

    // Assert both resets to flush the FIFO.
    always @(posedge wclk or negedge wrstn) begin
        if (!wrstn) begin
            rptr_buff <= 0;
            rptr_syn <= 0;
        end else begin
            rptr_buff <= rptr;
            rptr_syn <= rptr_buff;
        end
    end

    always @(posedge rclk or negedge rrstn) begin
        if (!rrstn) begin
            wptr_buff <= 0;
            wptr_syn <= 0;
        end else begin
            wptr_buff <= wptr;
            wptr_syn <= wptr_buff;
        end
    end

    function [ADDR_WIDTH:0] gray_to_binary(input [ADDR_WIDTH:0] gray);
        integer bit_index;
        begin
            gray_to_binary[ADDR_WIDTH] = gray[ADDR_WIDTH];
            for (bit_index = ADDR_WIDTH - 1; bit_index >= 0; bit_index = bit_index - 1)
                gray_to_binary[bit_index] = gray_to_binary[bit_index + 1] ^ gray[bit_index];
        end
    endfunction

    wire [ADDR_WIDTH:0] write_used = waddr_bin - gray_to_binary(rptr_syn);
    assign wfull = (write_used == CAPACITY);
    assign rempty = (rptr == wptr_syn);

    wire [RAM_ADDR_WIDTH-1:0] waddr, raddr;
    generate
        if (DEPTH == 1) begin : single_slot
            assign waddr = 0;
            assign raddr = 0;
        end else if ((DEPTH & (DEPTH - 1)) == 0) begin : power_of_two
            assign waddr = waddr_bin[RAM_ADDR_WIDTH-1:0];
            assign raddr = raddr_bin[RAM_ADDR_WIDTH-1:0];
        end else begin : wrap_ram_addresses
            // Keep the CDC pointers on a power-of-two ring for single-bit
            // Gray transitions. The physical addresses wrap at DEPTH.
            localparam [RAM_ADDR_WIDTH-1:0] LAST_ADDR = DEPTH - 1;
            reg [RAM_ADDR_WIDTH-1:0] write_addr, read_addr;

            always @(posedge wclk or negedge wrstn) begin
                if (!wrstn)
                    write_addr <= 0;
                else if (wen)
                    write_addr <= (write_addr == LAST_ADDR) ? 0 : write_addr + 1'b1;
            end

            always @(posedge rclk or negedge rrstn) begin
                if (!rrstn)
                    read_addr <= 0;
                else if (ren)
                    read_addr <= (read_addr == LAST_ADDR) ? 0 : read_addr + 1'b1;
            end

            assign waddr = write_addr;
            assign raddr = read_addr;
        end
    endgenerate

    dual_port_RAM #(.DEPTH(DEPTH), .WIDTH(WIDTH)) u_ram (
        .wclk(wclk),
        .wenc(wen),
        .waddr(waddr),
        .wdata(wdata),
        .rclk(rclk),
        .renc(ren),
        .raddr(raddr),
        .rdata(rdata)
    );
endmodule

module dual_port_RAM #(parameter DEPTH = 16,
   parameter WIDTH = 8)(
 input wclk
,input wenc
,input [$clog2(DEPTH)-1:0] waddr
,input [WIDTH-1:0] wdata
,input rclk
,input renc
,input [$clog2(DEPTH)-1:0] raddr
,output reg [WIDTH-1:0] rdata
);

reg [WIDTH-1:0] RAM_MEM [0:DEPTH-1];

always @(posedge wclk) begin
if(wenc)
RAM_MEM[waddr] <= wdata;
end

always @(posedge rclk) begin
if(renc)
rdata <= RAM_MEM[raddr];
end

endmodule
