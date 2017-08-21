#include <stdlib.h>
#include <stdio.h>
#include <errno.h>
#include <string.h>
#include <unistd.h>
#include <signal.h>
#include <setjmp.h>

#include <sys/mman.h>

#define UINT(addr) (*(uint32_t*)(addr))

static __thread sigjmp_buf sig_hdlr_env;

void sigsegv_handler(int sig);

// clang -std=c99 -Wall -o memtrap memtrap.c

int main(int argc, char* argv[]) {
	struct sigaction sig_act;
	sig_act.sa_handler = sigsegv_handler;
	sigemptyset(&sig_act.sa_mask);
	sig_act.sa_flags = 0;
	
	// TODO use #ifdef __APPLE__ to register SIGBUS ( use SIGSEGV on Linux )
	if (sigaction(SIGBUS, &sig_act, NULL) == -1) {
		fprintf(stderr, "signal handler registration failed: %s\n", strerror(errno));
		return EXIT_FAILURE;
	}
	
	printf("signal handler registered\n");
	
	// memory page with disabled access
	void* trap_blk = mmap(NULL, 4096, PROT_NONE, MAP_ANON | MAP_PRIVATE, -1, 0);
	
	int recovered = sigsetjmp(sig_hdlr_env, 1);
	if (!recovered) {
		printf("stand by...\n");
		// boom
		UINT(trap_blk) = 1;
		printf("val = %d\n", UINT(trap_blk));
	} else {
		printf("recovered\n");
	}
	
	return EXIT_SUCCESS;
}

void sigsegv_handler(int sig) {
	// SA_SIGINFO can be used to obtain mem address which caused SIGSEGV
	char* msg = "protected mem access trapped\n";
	write(STDOUT_FILENO, msg, strlen(msg));
	siglongjmp(sig_hdlr_env, 1);
}