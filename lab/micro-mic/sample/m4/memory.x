MEMORY
{
    /* Flash Bank 2 */
    FLASH : ORIGIN = 0x08100000, LENGTH = 1024K
    RAM   : ORIGIN = 0x30000000, LENGTH = 288K
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