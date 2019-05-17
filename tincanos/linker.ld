SECTIONS {
	. = 32K;
	
	.data : {
		*(.data)
	}
	
	. = ALIGN(4K);

	.text : {
		*(.text)
	}
	
	. = ALIGN(4K);

	.bss : {
		*(.bss)
		. = ALIGN(4K);
		. = 8K;
		STACK_TOP = .;
	}
}
