#include <stdio.h>
#include <string.h>
#include <time.h>
#include <sys/time.h>

#ifdef __linux__
// required for pid_t
#define __USE_XOPEN
// required for MAP_ANON
#define __USE_MISC
// required for srandom
#define __USE_BSD
#endif

#include <stdlib.h>
#include <unistd.h>
#include <sys/mman.h>

// clang -std=c99  -Wall -o memmap memmap.c
// gcc -std=c99 -Wall -o memmap memmap.c

const size_t MALLOC_BLKS = 1;
const size_t MEM_BLK_SZ = 1024 * 1024;

static void print_bytes(const unsigned char* blk, size_t len) {
    if (len > 0) {
        for (int i = 0;i < len;i++) {
            printf("%02X ", blk[i]);
        }
    }
    
    printf("\n");
}

static suseconds_t duration_in_ms(const struct timeval* start, const struct timeval* end) {
    return (end->tv_sec - start->tv_sec) * 1000 + (end->tv_usec - start->tv_usec) / 1000;
}

static suseconds_t duration_in_us(const struct timeval* start, const struct timeval* end) {
    return (end->tv_sec - start->tv_sec) * 1000000 + (end->tv_usec - start->tv_usec);
}

static void fill_with_rnd_bytes(void* buf, size_t len) {
    if (len <= 0) {
        return;
    }
    
    printf("filling buffer of length %lu\n", len);
    
    struct timeval start;
    gettimeofday(&start, NULL);
    
    // seeding random number generator
    time_t t = time(NULL);
    srandom(t);
    
    long rnd = 0;
    int it = len / sizeof(rnd);
    
    printf("iterations count = %d\n", it);
    
    for (int i = 0;i < it;i++) {
        rnd = random();
        memcpy(buf + i * sizeof(rnd), &rnd, sizeof(rnd));
    }
    
    // filling buffer left over
    rnd = random();
    size_t pos = it * sizeof(rnd);
    memcpy(buf + (it * sizeof(rnd)), &rnd, len - pos);
    
    struct timeval end;
    gettimeofday(&end, NULL);
    
    suseconds_t d = duration_in_ms(&start, &end);
    printf("buffer filled in %lu ms\n", d);
}

static void create_mem_mapping() {
	printf("creating new memory mapping\n");
	// allocating large memory block
    
    size_t mem_blk_len = 128 * MEM_BLK_SZ;
    
	void* mem_blk = mmap(NULL, mem_blk_len, PROT_READ | PROT_WRITE, MAP_PRIVATE | MAP_ANONYMOUS, -1, 0);
	if (mem_blk == MAP_FAILED) {
		perror("source memory block allocation failed");
		exit(EXIT_FAILURE);
	}
	
    printf("source memory block allocated @ %p\n", mem_blk);
    fill_with_rnd_bytes(mem_blk, mem_blk_len);
    
	printf("source memory block initialized\n");
    print_bytes(mem_blk, 16);
    
    void* dest_mem_blk = mmap(NULL, mem_blk_len, PROT_READ | PROT_WRITE, MAP_PRIVATE | MAP_ANONYMOUS, -1, 0);
	if (mem_blk == MAP_FAILED) {
		perror("destination memory block allocation failed");
		exit(EXIT_FAILURE);
	}
    
    struct timeval start;
    gettimeofday(&start, NULL);
    
    memcpy(dest_mem_blk, mem_blk, mem_blk_len);
    
    struct timeval end;
    gettimeofday(&end, NULL);
    
    suseconds_t us = duration_in_us(&start, &end);
    printf("memory block of size %lu copied in %lu us\n", mem_blk_len, us);
    
	sleep(1);
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
		printf("memory block allocated @ %p - content: ", mem_blk);
        print_bytes(mem_blk, 8);
	}
	printf("memory allocation completed\n");
	
	sleep(1);
	
	create_mem_mapping();
	
	printf("stopping memory allocator...\n");
	return EXIT_SUCCESS;
}