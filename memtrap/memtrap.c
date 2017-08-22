#include <stdlib.h>
#include <stdio.h>
#include <errno.h>
#include <string.h>
#include <unistd.h>
#include <signal.h>
#include <setjmp.h>
#include <time.h>
#include <pthread.h>

#include <sys/mman.h>

#include <stdbool.h>

#define UINT(addr) (*(uint32_t*)(addr))

const int THREAD_COUNT = 4;

// making jump environment thread local
static __thread sigjmp_buf sig_hdlr_env;
void* trap_blk;

void mem_acc_violation_handler(int sig);

void* mem_access_activity(void* arg);

struct ThreadArgs {
	bool try_access;
	int tid;
};

// clang -std=c99 -Wall -o memtrap memtrap.c

int main(int argc, char* argv[]) {
	struct sigaction sig_act;
	sig_act.sa_handler = mem_acc_violation_handler;
	sigemptyset(&sig_act.sa_mask);
	sig_act.sa_flags = 0;
	
	// TODO use #ifdef __APPLE__ to register SIGBUS ( use SIGSEGV on Linux )
	if (sigaction(SIGBUS, &sig_act, NULL) == -1) {
		fprintf(stderr, "signal handler registration failed: %s\n", strerror(errno));
		return EXIT_FAILURE;
	}
	
	// creating protected mem page
	trap_blk = mmap(NULL, 4096, PROT_NONE, MAP_ANON | MAP_PRIVATE, -1, 0);
	
	srand(time(NULL));
	
	pthread_t tids[THREAD_COUNT];
	// it's highly unsafe to pass ptr to locals into independent threads
	// here we are using the fact that we are joining to them
	struct ThreadArgs targs[THREAD_COUNT];
	memset(targs, 0, sizeof(targs));
	
	// marking thread which will try to perform protected page access
	targs[0].try_access = true;
	targs[1].try_access = true;
	
	for (int tidx = 0;tidx < THREAD_COUNT;tidx++) {
		// using index as thread id
		targs[tidx].tid = tidx;
		int status = pthread_create(&tids[tidx], NULL, mem_access_activity, &targs[tidx]);
		if (status != 0) {
			fprintf(stderr, "thread creation failed: %s\n", strerror(status));
			return EXIT_FAILURE;
		}
	}
	
	for (int tidx = 0;tidx < THREAD_COUNT;tidx++) {
		pthread_join(tids[tidx], NULL);
	}
	
	printf("exiting...\n");
	
	return EXIT_SUCCESS;
}

void mem_acc_violation_handler(int sig) {
	// SA_SIGINFO can be used to obtain mem address which caused SIGSEGV
	// recovering
	siglongjmp(sig_hdlr_env, 1);
}

void* mem_access_activity(void* arg) {
	struct ThreadArgs targ = *(struct ThreadArgs*)arg;
	
	int ticks = 0, i = 0;
	// recovery point
	int recovered = sigsetjmp(sig_hdlr_env, 1);
	while (i < 64) {
		if (!recovered) {
			int rnd_num = rand();
			// sleep(1);
			if (targ.try_access && rnd_num % 37 == 0) {
				printf("try mem acc tid: %d\n", targ.tid);
				UINT(trap_blk) = 1;
			} else {
				ticks++;
				// printf("tick\n");
			}
		} else {
			// clearing recovery flag
			// protected memory access was effectively skipped at this point
			printf("mem acc fail tid: %d\n", targ.tid);
			recovered = 0;
		}
		
		i++;
	}
	
	printf("ticks = %d\n", ticks);
	
	return NULL;
}