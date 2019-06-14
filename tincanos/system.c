typedef __SIZE_TYPE__ size_t;

typedef unsigned int uint32_t;

// the origin of screen buffer in memory
#define SCRN_BUF_ORG 0xb8000

#define SCRN_COLS 80
#define SCRN_ROWS 24

const char* const SCRN_BUF_END = (char*)(SCRN_BUF_ORG + SCRN_COLS*SCRN_ROWS*2);

const char HEX_DIGITS[16] = "0123456789abcdef";

static size_t row = 0;

static size_t col = 0;

size_t strlen(const char* str);

void print(const char* str);

void int2hex(uint32_t i, char* buf);

uint32_t get_eflags();

void start() {
	print("Hello, metal!\n");

	print("eflags: ");
	char hex_buf[12] = "0x00000000\n";
	uint32_t eflags = get_eflags();
	int2hex(eflags, &hex_buf[2]);
	print(hex_buf);

	int q = 5 / 0;

	print("divide error trapped");

	// infinite loop
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
