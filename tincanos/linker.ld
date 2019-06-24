TSS_SIZE = 104;

OUTPUT_FORMAT ("elf32-i386", "elf32-i386", "elf32-i386")
OUTPUT_ARCH(i386)
SECTIONS {
	. = 32K;
	
	.data : {
		*(.data)
		. = ALIGN(16);
		*(.rodata)
	}
	
	. = ALIGN(4K);

	.text : {
		*(.text)
	}
	
	. = ALIGN(4K);

	.bss : {
		*(.bss)
		. = ALIGN(4K);
		. = . + 8K;
		SYS_TSS_BASE = .;

		STACK_TOP = SYS_TSS_BASE - 4;

		. = . + TSS_SIZE;

		USR_TSS_BASE = .;
	}
}
