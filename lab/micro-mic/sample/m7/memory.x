MEMORY
{
    /* Flash Bank 1 */
    FLASH : ORIGIN = 0x08000000, LENGTH = 1024K
    /* DTCM RAM */
    RAM   : ORIGIN = 0x24000000, LENGTH = 512K
    /* LOGS */
    SHARED_RAM (rw) : ORIGIN = 0x38000000, LENGTH = 64K
}

/* Static variables */
SECTIONS 
{
    .shared_ipc (NOLOAD) : ALIGN(4) {
        *(.shared_ipc);
        . = ALIGN(4);
    } > SHARED_RAM
}