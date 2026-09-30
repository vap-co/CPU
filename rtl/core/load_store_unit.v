`timescale 1ns / 1ps

// Byte/half-word/word extraction and store-lane generation for RV32I.
module load_store_unit(
    input  [31:0] mem_rdata,
    input  [31:0] store_data,
    input  [1:0]  addr_lsb,
    input  [2:0]  funct3,
    output reg [31:0] load_data,
    output reg [31:0] store_wdata,
    output reg [3:0]  store_wstrb
);
    reg [7:0]  selected_byte;
    reg [15:0] selected_half;

    always @(*) begin
        case (addr_lsb)
            2'b00: selected_byte = mem_rdata[7:0];
            2'b01: selected_byte = mem_rdata[15:8];
            2'b10: selected_byte = mem_rdata[23:16];
            default: selected_byte = mem_rdata[31:24];
        endcase

        selected_half = addr_lsb[1] ? mem_rdata[31:16] : mem_rdata[15:0];

        case (funct3)
            3'b000: load_data = {{24{selected_byte[7]}}, selected_byte}; // LB
            3'b001: load_data = {{16{selected_half[15]}}, selected_half}; // LH
            3'b010: load_data = mem_rdata;                                // LW
            3'b100: load_data = {24'b0, selected_byte};                   // LBU
            3'b101: load_data = {16'b0, selected_half};                   // LHU
            default: load_data = mem_rdata;
        endcase

        store_wdata = 32'b0;
        store_wstrb = 4'b0000;
        case (funct3)
            3'b000: begin // SB
                case (addr_lsb)
                    2'b00: begin store_wstrb=4'b0001; store_wdata={24'b0,store_data[7:0]}; end
                    2'b01: begin store_wstrb=4'b0010; store_wdata={16'b0,store_data[7:0],8'b0}; end
                    2'b10: begin store_wstrb=4'b0100; store_wdata={8'b0,store_data[7:0],16'b0}; end
                    default: begin store_wstrb=4'b1000; store_wdata={store_data[7:0],24'b0}; end
                endcase
            end
            3'b001: begin // SH
                if (addr_lsb[1]) begin
                    store_wstrb = 4'b1100;
                    store_wdata = {store_data[15:0],16'b0};
                end else begin
                    store_wstrb = 4'b0011;
                    store_wdata = {16'b0,store_data[15:0]};
                end
            end
            3'b010: begin // SW
                store_wstrb = 4'b1111;
                store_wdata = store_data;
            end
            default: begin
                store_wstrb = 4'b0000;
                store_wdata = 32'b0;
            end
        endcase
    end
endmodule
