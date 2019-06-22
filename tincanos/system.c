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

extern struct tss* sys_tss_base;
extern void* usr_tss_base;

const char* const SCRN_BUF_END = (char*)(SCRN_BUF_ORG + SCRN_COLS*SCRN_ROWS*2);

const char HEX_DIGITS[16] = "0123456789abcdef";

static size_t row = 0;

static size_t col = 0;

size_t strlen(const char* str);

void print(const char* str);

void int2hex(uint32_t i, char* buf);

uint32_t get_eflags();

uint32_t get_ldtr();

// user level task entry point
void task();

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

void start() {
	print("Hello, metal!\n");

	print("usr tss eip: ");
	char hex_buf[12] = "0x00000000\n";
	// int2hex(*(uint32_t*)(usr_tss_base + 32), &hex_buf[2]);
	int2hex(*((int*)0x8000), &hex_buf[2]);
	print(hex_buf);

	// int q = 5 / 0;
	// print("divide error trapped");
	memset(sys_tss_base, 0, sizeof(struct tss));
	sys_tss_base->cs = 0x8;

	struct tss usr_tss;
	memset(&usr_tss, 0, sizeof(usr_tss));

	// configuring stack swiching parameters
	usr_tss.esp0 = SYS_ISR_STACK;
	usr_tss.ss0 =  SYS_DATA_SEG_SEL;
	usr_tss.esp1 = usr_tss.esp0;
	usr_tss.ss1 =  usr_tss.ss0;
	usr_tss.esp2 = usr_tss.esp0;
	usr_tss.ss2 =  usr_tss.ss0;

	// TODO point to the first instruction of user level task
	usr_tss.eip = task;

	uint32_t eflags = get_eflags();
	usr_tss.eflags = eflags;

	usr_tss.esp = USR_STACK;

	usr_tss.cs = USR_CODE_SEG_SEL;
	usr_tss.ds = USR_DATA_SEG_SEL;
	usr_tss.es = usr_tss.ds;
	usr_tss.ss = usr_tss.ds;
	usr_tss.fs = usr_tss.ds;
	usr_tss.gs = usr_tss.ds;

	// making I/O map base addr offset larger than segment limit indicating that I/O map not initialized
	usr_tss.iomap_base = 0x680000;

	// copying user TSS data to TSS segment
	memcpy(usr_tss_base, &usr_tss, sizeof(usr_tss));

	// infinite loop
	// for (;;);
}

void user_task() {
	uint32_t cs_reg = get_ldtr();
	
	print("code segment register: ");
	char hex_buf[12] = "0x00000000\n";
	int2hex(cs_reg, &hex_buf[2]);
	print(hex_buf);

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
