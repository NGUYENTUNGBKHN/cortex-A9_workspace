# -----------------------------------------------------------------------------
# U-Boot SPL Debugging Script
# -----------------------------------------------------------------------------

# Halt the processor to prepare for image loading
echo \n[INFO] Halting target system...\n
monitor halt

# Load the SPL binary and Device Tree Blob (DTB) to memory
echo [INFO] Loading SPL images and DTB...\n
monitor load_image uboot_3/u-boot-spl
monitor load_image uboot_3/u-boot-spl.dtb 0xFFFFBF44 bin

# Initialize the Program Counter (PC) and load symbol table
echo [INFO] Initializing PC and symbols...\n
monitor reg pc 0xFFFF0000
symbol-file uboot_3/u-boot-spl

# Set breakpoints for critical boot stages
echo [INFO] Setting breakpoint at spl_boot_device...\n
break spl_boot_device

# Start execution
echo [INFO] System ready. Resuming execution...\n
continue

