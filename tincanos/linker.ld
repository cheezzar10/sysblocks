ENTRY(init_start)

SECTIONS {
	. = 1M;
	
	code : {
		*(.text)
	}
	
	data : {
		*(.data)
	}
	
	bss : {
		*(.bss)
		BSS_END = .;
		. = ALIGN(4K);
		. = 128K;
		STACK_TOP = .;
	}
}