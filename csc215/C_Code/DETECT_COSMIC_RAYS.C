#include <stdio.h>
/* Nikita Kolesnikov - CSC215, 2025-26
DETECT_COSMIC_RAYS - Memory integrity checker using static patterns
Detects potential bit flips in memory (cosmic radiation, hardware faults, sabotage)
Inspired by a joke on Discord that I actually thought a useful thing to make
Usage: Include in programs and call detect_cosmic_rays() at start and end */

#define PATTERN_SIZE 6

/* Reference patterns for memory integrity check */
static long reference_hi[PATTERN_SIZE] = {
    0xDEADBEEF, 0xCAFEBABE, 0x01234567,
    0x0F0F0F0F, 0xAAAAAAAA, 0x55555555
};

static long reference_lo[PATTERN_SIZE] = {
    0xDEADBEEF, 0xCAFEBABE, 0x89ABCDEF,
    0x0F0F0F0F, 0xAAAAAAAA, 0x55555555
};

/* Check block - will be tested against reference */
static long check_hi[PATTERN_SIZE] = {0, 0, 0, 0, 0, 0};
static long check_lo[PATTERN_SIZE] = {0, 0, 0, 0, 0, 0};
static int initialized = 0;

/* Main detection routine - call at program start and end */
void detect_cosmic_rays()
{
    int i;

    /* First call: initialize check block */
    if (!initialized) {
        for (i = 0; i < PATTERN_SIZE; i++) {
            check_hi[i] = reference_hi[i];
            check_lo[i] = reference_lo[i];
        }
        initialized = 1;
        return;
    }

    /* Subsequent calls: verify data integrity */
    for (i = 0; i < PATTERN_SIZE; i++) {
        if (check_hi[i] != reference_hi[i] ||
            check_lo[i] != reference_lo[i]) {
            printf("\n[ALERT] Somehow, a bit flipped![%d]!\n", i);
            printf("Expected: %08lX%08lX\n",
                   reference_hi[i], reference_lo[i]);
            printf("Found:    %08lX%08lX\n",
                   check_hi[i], check_lo[i]);
            return;
        }
    }
}
