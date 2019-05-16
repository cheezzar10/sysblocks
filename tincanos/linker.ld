SECTIONS {
	. = 32K;
	
	.data : {
		*(.data)
	}
	
	. = ALIGN(4K);

	.isr : {
		ISR_ADDR = .;
		isr.o (.text)
	}

	ISR_ADDR_LO = ISR_ADDR & 0XFFFF;

	. = ALIGN(4K);

	.text : {
		hello.o (.text)
	}
	
	. = ALIGN(4K);

	.bss : {
		*(.bss)
		. = ALIGN(4K);
		. = 8K;
		STACK_TOP = .;
	}
}
