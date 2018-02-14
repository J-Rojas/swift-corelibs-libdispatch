#include <limits.h>
#include <sys/param.h>

static inline int32_t
OSAtomicIncrement32(volatile int32_t *var)
{
  return __c11_atomic_fetch_add((_Atomic(int)*)var, 1, __ATOMIC_RELAXED)+1;
}

static inline int32_t
OSAtomicIncrement32Barrier(volatile int32_t *var)
{
    return __c11_atomic_fetch_add((_Atomic(int)*)var, 1, __ATOMIC_SEQ_CST)+1;
}

static inline int32_t
OSAtomicAdd32(int32_t val, volatile int32_t *var)
{
    return __c11_atomic_fetch_add((_Atomic(int)*)var, val, __ATOMIC_RELAXED)+val;
}

// Simulation of mach_absolute_time related infrastructure
// For now, use gettimeofday.
// Consider using clockgettime(CLOCK_MONOTONIC) instead.

#include <sys/time.h>

struct mach_timebase_info {
  uint32_t numer;
  uint32_t denom;
};

typedef struct mach_timebase_info *mach_timebase_info_t;
typedef struct mach_timebase_info mach_timebase_info_data_t;

typedef int kern_return_t;

static inline
uint64_t
mach_absolute_time()
{
	struct timeval tv;
	gettimeofday(&tv,NULL);
	return (1000ull)*((unsigned long long)tv.tv_sec*(1000000ull) + (unsigned long long)tv.tv_usec);
}

static inline
int
mach_timebase_info(mach_timebase_info_t tbi)
{
	tbi->numer = 1;
	tbi->denom = 1;
	return 0;
}

/*
 * Android declares but does not implement posix_spawnp().
 */
#ifdef __ANDROID__
#include <spawn.h>
static inline int posix_spawnp(pid_t* __pid, const char* __file, 
                const posix_spawn_file_actions_t* __actions __attribute__((unused)), const posix_spawnattr_t* __attr __attribute__((unused)), 
                char* const __argv[], char* const __env[]){
    pid_t pid = fork();
    if (__pid != NULL) {
        *__pid = pid;
    }
    return execve(__file, __argv, __env);
}

static inline int posix_spawnattr_init(posix_spawnattr_t* __attr __attribute__((unused))) {
	return 0;
}

static inline int posix_spawnattr_setflags(posix_spawnattr_t* __attr __attribute__((unused)), short __flags __attribute__((unused))) {
	return 0;
}

#endif
