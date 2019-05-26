typedef __SIZE_TYPE__ size_t;

// the origin of screen buffer in memory
#define SCRN_BUF_ORG 0xb8000

#define SCRN_COLS 80
#define SCRN_ROWS 24

const char* const SCRN_BUF_END = (char*)(SCRN_BUF_ORG + SCRN_COLS*SCRN_ROWS*2);

// current screen buffer position
static char* scrn_buf = (char*)SCRN_BUF_ORG;

static size_t row = 0;

static size_t col = 0;

size_t strlen(const char* str);

void print(const char* str);

void start() {
	print("Hello, metal!\n");
	print("addr: ");

	// infinite loop
	for (;;);
}

void print(const char* s) {
	char* scrn_buf = SCRN_BUF_ORG + 2*80*row + col*2;

	for (size_t si = 0;s[si] != '\0';si++) {
		if (s[si] == '\n') {
			scrn_buf += (SCRN_COLS - col)*2;

			row++;
			col = 0;
		} else {
			*scrn_buf = s[si];
			scrn_buf += 2;
		}
	}
}

size_t strlen(const char* str) {
	unsigned int offset = 0;
	for (;str[offset] != '\0';offset++);
	return offset;
}
