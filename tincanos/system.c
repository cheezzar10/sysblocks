char* const DISPLAY_BUF = (char*)0xB8000;

const unsigned int DISPLAY_COLUMNS = 80;

const unsigned int DISPLAY_LINES = 24;

static unsigned int line = 0;

static unsigned int column = 0;

unsigned int StrLen(const char* str);

void PrintLn(const char* str);

void sysstart() {
	char msg[] = "image";
	// unsigned int len = StrLen(msg);
	PrintLn(msg);
}

unsigned int StrLen(const char* str) {
	unsigned int offset = 0;
	for (;str[offset] != '\0';offset++);
	return offset;
}

void PrintLn(const char* str) {
	unsigned int displayBufOffset = line*DISPLAY_COLUMNS*2 + column*2;
	
	unsigned int strLen = StrLen(str);
	for (unsigned int strOffset=0;strOffset<strLen;strOffset++) {
		DISPLAY_BUF[displayBufOffset] = str[strOffset];
		displayBufOffset += 2;
		strOffset++;
		
		column++;
		if (column == DISPLAY_COLUMNS) {
			column = 0;
			line++;
		}
	}
	
	column=0;
	line++;
}

