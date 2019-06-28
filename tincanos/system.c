typedef __SIZE_TYPE__ size_t;

typedef unsigned int uint32_t;

// the origin of screen buffer in memory
#define SCRN_BUF_ORG 0xb8000

#define SCRN_COLS 80
#define SCRN_ROWS 24

// placing priviliged code stack at 64k boundary
#define SYS_ISR_STACK 0xfffc
#define SYS_DATA_SEG_SEL 0x10

// placing user level stack at 128k boundary
#define USR_STACK 0x1fffc
#define USR_CODE_SEG_SEL 0x1b
#define USR_DATA_SEG_SEL 0x23
#define USR_TSS_SEL 0x30

extern struct tss* sys_tss_ptr;
extern struct tss* usr_tss_ptr;

const char* const SCRN_BUF_END = (char*)(SCRN_BUF_ORG + SCRN_COLS*SCRN_ROWS*2);

const char HEX_DIGITS[16] = "0123456789abcdef";

static size_t row = 0;

static size_t col = 0;

size_t strlen(const char* str);

void print(const char* str);

void int2hex(uint32_t i, char* buf);

// TODO the following functions should be moved to init.h
uint32_t get_eflags();

uint32_t get_ldtr();

void pic_init();

// TODO uint16_t actually
void task_switch(uint32_t tss_sel);

// end of system initialization functions header

struct tss {
	uint32_t pvt;
	uint32_t esp0;
	uint32_t ss0;
	uint32_t esp1;
	uint32_t ss1;
	uint32_t esp2;
	uint32_t ss2;
	uint32_t cr3;
	uint32_t eip;
	uint32_t eflags;
	uint32_t eax;
	uint32_t ecx;
	uint32_t edx;
	uint32_t ebx;
	uint32_t esp;
	uint32_t ebp;
	uint32_t esi;
	uint32_t edi;
	uint32_t es;
	uint32_t cs;
	uint32_t ss;
	uint32_t ds;
	uint32_t fs;
	uint32_t gs;
	uint32_t ldt;
	uint32_t iomap_base;
};

void* memset(void* dst, int c, size_t n) {
	char* d = dst;
	for (size_t i=0;i<n;i++) {
		d[i] = c;
	}
	return dst;
}

void* memcpy(void* dst, const void* src, size_t n) {
	char* d = dst;
	const char* s = src;
	for (int i=0;i<n;i++) {
		d[i] = s[i];
	}
	return dst;
}

void usr_init() {
	uint32_t eflags = get_eflags();
	
	print("eflags: ");
	char hex_buf[12] = "0x00000000\n";
	int2hex(eflags, &hex_buf[2]);
	print(hex_buf);

	// call intr(49) where system task gate will be placed

	for (;;);
}

void sys_init() {
	print("OS primitives testbench started\n");

	pic_init();

	print("null gdt entry: ");
	char hex_buf[12] = "0x00000000\n";
	// int2hex(*(uint32_t*)(usr_tss_base + 32), &hex_buf[2]);
	int2hex(*((int*)0x8000), &hex_buf[2]);
	print(hex_buf);

	// int q = 5 / 0;
	// print("divide error trapped");

	memset(sys_tss_ptr, 0, sizeof(struct tss));
	memset(usr_tss_ptr, 0, sizeof(struct tss));

	// configuring stack swiching parameters
	usr_tss_ptr->esp0 = SYS_ISR_STACK;
	usr_tss_ptr->ss0 = SYS_DATA_SEG_SEL;
	usr_tss_ptr->esp1 = SYS_ISR_STACK;
	usr_tss_ptr->ss1 = SYS_DATA_SEG_SEL;
	usr_tss_ptr->esp2 = SYS_ISR_STACK;
	usr_tss_ptr->ss2 = SYS_DATA_SEG_SEL;

	// user level task starts by calling usr_init
	usr_tss_ptr->eip = usr_init;

	usr_tss_ptr->eflags = get_eflags();

	usr_tss_ptr->esp = USR_STACK;

	usr_tss_ptr->cs = USR_CODE_SEG_SEL;
	usr_tss_ptr->ds = USR_DATA_SEG_SEL;
	usr_tss_ptr->ss = USR_DATA_SEG_SEL;
	usr_tss_ptr->es = USR_DATA_SEG_SEL;
	usr_tss_ptr->fs = USR_DATA_SEG_SEL;
	usr_tss_ptr->gs = USR_DATA_SEG_SEL;

	// making I/O map base addr offset larger than segment limit indicating that I/O map not initialized
	usr_tss_ptr->iomap_base = 0x680000;
	usr_tss_ptr->ldt = 0x38;

	sys_tss_ptr->pvt = USR_TSS_SEL;
	task_switch(USR_TSS_SEL);

	// TODO place syscalls dispatcher here
	for (;;);
}

void print(const char* s) {
	char* scrn_buf = (char*)(SCRN_BUF_ORG + 2*80*row + col*2);

	for (size_t si = 0;s[si] != '\0';si++) {
		if (s[si] == '\n') {
			scrn_buf += (SCRN_COLS - col)*2;

			row++;
			col = 0;
		} else {
			*scrn_buf = s[si];
			scrn_buf += 2;
			col++;
		}
	}
}

size_t strlen(const char* str) {
	unsigned int offset = 0;
	for (;str[offset] != '\0';offset++);
	return offset;
}

void int2hex(uint32_t n, char* buf) {
	for (size_t i = 8;i > 0; i--) {
		buf[i-1] = HEX_DIGITS[n & 0xf];
		n >>= 4;
	}
}
