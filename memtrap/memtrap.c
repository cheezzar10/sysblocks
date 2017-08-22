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

#define UINT(addr) (*(uint32_t*)(addr))

const int THREAD_COUNT = 4;

// making jump environment thread local
static __thread sigjmp_buf sig_hdlr_env;
void* trap_blk;

void mem_acc_violation_handler(int sig);

void* mem_access_activity(void* arg);

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
	uint32_t targs[THREAD_COUNT];
	memset(targs, 0, sizeof(targs));
	targs[0] = 1;
	for (int tidx = 0;tidx < THREAD_COUNT;tidx++) {
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
	uint32_t perform_acc = *(uint32_t*)arg;
	
	int ticks = 0, i = 0;
	int recovered = sigsetjmp(sig_hdlr_env, 1);
	while (i < 64) {
		if (!recovered) {
			int rnd_num = rand();
			// sleep(1);
			if (perform_acc && rnd_num % 11 == 0) {
				UINT(trap_blk) = 1;
			} else {
				ticks++;
				// printf("tick\n");
			}
		} else {
			recovered = 0;
		}
		
		i++;
	}
	
	printf("ticks = %d\n", ticks);
	
	return NULL;
}