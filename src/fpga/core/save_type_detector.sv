//
// save_type_detector.sv — Detect save type and hardware features from ROM download stream
//
// Watches the data_loader output (rom_wr / rom_data) during ROM loading and
// uses shift registers and header decoding to detect:
//   - "FLASH1M_V" : 128K Flash save type
//   - "SIIRTC_V"  : Seiko S-3511A Real-Time Clock driver signature in ROM
//   - Cart ID     : captured from ROM header at 0xAC-0xAF
//   - Cart Title  : captured from ROM header at 0xA0-0xAB to auto-detect known RTC ROM hacks
//
// MiSTer only detects flash_1m from the ROM string. SramFlashEnable defaults
// to ON (~sram_quirk) and EEPROM is auto-detected by DMA at runtime in
// gba_memorymux.vhd.
//
// SPDX-License-Identifier: GPL-2.0-or-later
//

`default_nettype none

module save_type_detector (
    input  wire        clk,
    input  wire        reset,

    // ROM download stream (from data_loader, active during boot)
    input  wire        rom_wr,          // Write pulse from data_loader
    input  wire [15:0] rom_data,        // 16-bit word being written to SDRAM
    input  wire [27:0] rom_addr,        // Byte address from data_loader

    // Detection results
    output reg         flash_1m,        // 1 = 128K Flash (detected "FLASH1M_V")
    output reg         rtc_detected,    // 1 = RTC detected (via "SIIRTC_V" or known ROM hack title)

    // Cart ID captured from ROM header at byte offset 0xAC-0xAF
    // Stored big-endian (MiSTer-compatible) for cart_quirks matching
    output reg  [31:0] cart_id,
    output reg         cart_id_valid    // Latches high when rom_addr passes 0xB0 (MiSTer GBA.sv line 668)
);

    // ----------------------------------------------------------------
    // Shift register for string detection (MiSTer GBA.sv pattern)
    //
    // Each rom_wr provides a 16-bit word with:
    //   rom_data[7:0]  = byte at rom_addr
    //   rom_data[15:8] = byte at rom_addr + 1
    //
    // We shift in 2 bytes per write, low byte first (matching MiSTer):
    //   str <= {str[47:0], rom_data[7:0], rom_data[15:8]}
    //
    // Then check both byte orderings for:
    //   - "FLASH1M_V" (9 bytes = 72 bits):
    //       {str[63:0], rom_data[7:0]}                 — odd-aligned
    //       {str[55:0], rom_data[7:0], rom_data[15:8]} — even-aligned
    //   - "SIIRTC_V"  (8 bytes = 64 bits):
    //       {str[55:0], rom_data[7:0]}                 — ends on low byte
    //       {str[47:0], rom_data[7:0], rom_data[15:8]} — ends on high byte
    // ----------------------------------------------------------------

    reg [63:0] str;
    reg [95:0] cart_title;

    always @(posedge clk) begin
        if (reset) begin
            str           <= 64'd0;
            flash_1m      <= 1'b0;
            rtc_detected  <= 1'b0;
            cart_id       <= 32'd0;
            cart_id_valid <= 1'b0;
            cart_title    <= 96'd0;
        end else if (rom_wr) begin
            // --- String detection for Flash 1M (MiSTer GBA.sv lines 414-418) ---
            if ({str, rom_data[7:0]} == "FLASH1M_V")
                flash_1m <= 1'b1;
            if ({str[55:0], rom_data[7:0], rom_data[15:8]} == "FLASH1M_V")
                flash_1m <= 1'b1;

            // --- String detection for Seiko RTC ("SIIRTC_V", 8 bytes = 64 bits) ---
            if ({str[55:0], rom_data[7:0]} == "SIIRTC_V")
                rtc_detected <= 1'b1;
            if ({str[47:0], rom_data[7:0], rom_data[15:8]} == "SIIRTC_V")
                rtc_detected <= 1'b1;

            // Shift in new bytes
            str <= {str[47:0], rom_data[7:0], rom_data[15:8]};

            // --- Cart Title (0xA0-0xAB) and Cart ID (0xAC-0xAF) capture ---
            // ROM header bytes 0xA0-0xAF: data_loader sends 16-bit words.
            // Byte-swap each word ({rom_data[7:0], rom_data[15:8]}) to big-endian.
            if (rom_addr[27:4] == 24'hA) begin
                if (rom_addr[3:0] <= 4'hA)
                    cart_title[{4'hA - rom_addr[3:0], 3'd0} +: 16] <= {rom_data[7:0], rom_data[15:8]};
                else
                    cart_id[{4'hE - rom_addr[3:0], 3'd0} +: 16] <= {rom_data[7:0], rom_data[15:8]};
            end

            // Cart header is complete once we pass address 0xB0 (MiSTer GBA.sv line 668)
            if (rom_addr >= 28'hB0) begin
                cart_id_valid <= 1'b1;
                // Check known RTC ROM hack title signatures in header
                if (cart_title[95:16] == "POKEMON UNB"  ||
                    cart_title[95:16] == "POKEUNBOUND"  ||
                    cart_title[95:16] == "POKEMON RADI" ||
                    cart_title[95:24] == "RADICALRED"   ||
                    cart_title[95:24] == "LIQUIDCRYS"   ||
                    cart_title[95:24] == "INCLEMENTEM") begin
                    rtc_detected <= 1'b1;
                end
            end
        end
    end

endmodule
