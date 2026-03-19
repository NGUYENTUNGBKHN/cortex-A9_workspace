set remotetimeout 60

monitor reset halt

monitor load_image uboot_3/u-boot-spl 0xFFFF0000 elf

monitor load_image uboot_3/u-boot-spl.dtb 0xFFFFBF44 bin

monitor reg pc 0xFFFF0000

file uboot_3/u-boot-spl

break spl_boot_device

continue

file Debug/lab1.elf

load

break main

continue
