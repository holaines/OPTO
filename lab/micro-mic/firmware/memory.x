MEMORY
{
    /* Flash Bank 1, Cortex-M7 */
    FLASH : ORIGIN = 0x08000000, LENGTH = 1024K
    /* AXI SRAM, Cortex-M7 */
    RAM   : ORIGIN = 0x24000000, LENGTH = 512K
    /* D2 SRAM3, visible to Ethernet DMA */
    SRAM3 : ORIGIN = 0x30040000, LENGTH = 32K
}

SECTIONS
{
    .sram3 (NOLOAD) : ALIGN(32) {
        *(.sram3 .sram3.*);
        . = ALIGN(32);
    } > SRAM3
}
