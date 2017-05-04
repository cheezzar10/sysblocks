#include <stdio.h>
#include <stdlib.h>

/*
  allocate two blocks of 128MB each
  fill one of them with /dev/random
  copy on to another
 */

#ifdef __linux__
// required for pid_t
#define __USE_XOPEN
// required for MAP_ANON
#define __USE_MISC
#endif

#include <unistd.h>
#include <sys/mman.h>

// clang -std=c99  -Wall -o memmap memmap.c
// gcc -std=c99 -Wall -o memmap memmap.c

const size_t MALLOC_BLKS = 8;
const size_t MEM_BLK_SZ = 1024 * 1024;

void print_bytes(const char* blk, size_t len);

void create_mem_mapping() {
	printf("creating new memory mapping\n");
	// allocating large 16 mb memory block
	void* mem_blk_addr = mmap(NULL, 16 * MEM_BLK_SZ, PROT_READ | PROT_WRITE, MAP_PRIVATE | MAP_ANONYMOUS, -1, 0);
	if (mem_blk_addr == MAP_FAILED) {
		perror("memory mapping creation failed");
		exit(EXIT_FAILURE);
	}
	
	printf("new memory mapping successfully created @%p - content: ", mem_blk_addr);
    print_bytes(mem_blk_addr, 8);
	sleep(15);
}

int main(int argc, char* argv[]) {
	pid_t pid = getpid();
	
	printf("memory allocator with pid=%d started.\n", pid);
	
	printf("memory allocation started\n");
	for (int i = 0;i < MALLOC_BLKS;i++) {
		void* mem_blk = malloc(MEM_BLK_SZ);
		if (mem_blk == NULL) {
			printf("memory block allocation failed\n");
			perror("malloc failed");
			return EXIT_FAILURE;
		}
		
		sleep(1);
		printf("memory block allocated @%p - content: ", mem_blk);
        print_bytes(mem_blk, 8);
	}
	printf("memory allocation completed\n");
	
	sleep(5);
	
	create_mem_mapping();
	
	printf("stopping memory allocator...\n");
	return EXIT_SUCCESS;
}

void print_bytes(const char* blk, size_t len) {
    if (len > 0) {
        for (int i = 0;i < len;i++) {
            printf("%02X ", blk[i]);
        }
    }
    
    printf("\n");
}