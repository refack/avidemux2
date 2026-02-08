#include "ADM_default.h"
#include "fourcc.h"
#include <assert.h>
#include <stdio.h>
#include <string.h>

int main(int argc, char **argv)
{
    printf("Starting fourCC unit tests...\n");

    // Test get
    uint32_t fcc_divx = fourCC::get((const uint8_t *)"DIVX");
    // mmioFOURCC('D', 'I', 'V', 'X') is always LE-packed: ('D') | ('I'<<8) | ('V'<<16) | ('X'<<24)
    // 0x44 | 0x4900 | 0x560000 | 0x58000000 = 0x58564944
    if (fcc_divx != 0x58564944) {
        printf("Test get failed: expected 0x58564944, got 0x%08X\n", fcc_divx);
        return 1;
    }
    printf("Test get: passed\n");

    // Test tostring
    char *s1 = fourCC::tostring(fcc_divx);
    if (strcmp(s1, "DIVX") != 0) {
        printf("Test tostring failed: expected DIVX, got %s\n", s1);
        return 1;
    }
    printf("Test tostring: passed\n");

    // Test tostringBE
    char *s2 = fourCC::tostringBE(fcc_divx);
    // On LE machine, 0x58564944 has bytes [44, 49, 56, 58] (D, I, V, X)
    // tostringBE reverses them: [58, 56, 49, 44] -> "XVID"
#if defined(ADM_BIG_ENDIAN)
    const char *expectedBE = "DIVX";
#else
    const char *expectedBE = "XVID";
#endif
    if (strcmp(s2, expectedBE) != 0) {
        printf("Test tostringBE failed: expected %s, got %s\n", expectedBE, s2);
        return 1;
    }
    printf("Test tostringBE: passed\n");

    // Test check(uint32_t, const uint8_t*)
    if (!fourCC::check(fcc_divx, (const uint8_t *)"DIVX")) {
        printf("Test check(uint32_t, DIVX) failed\n");
        return 1;
    }
    if (fourCC::check(fcc_divx, (const uint8_t *)"XVID")) {
        printf("Test check(uint32_t, XVID) failed\n");
        return 1;
    }
    printf("Test check(uint32_t, const uint8_t*): passed\n");

    // Test check(const uint8_t*, uint32_t)
    if (!fourCC::check((const uint8_t *)"DIVX", fcc_divx)) {
        printf("Test check(DIVX, uint32_t) failed\n");
        return 1;
    }
    if (fourCC::check((const uint8_t *)"XVID", fcc_divx)) {
        printf("Test check(XVID, uint32_t) failed\n");
        return 1;
    }
    printf("Test check(const uint8_t*, uint32_t): passed\n");

    // Test check(uint8_t*, uint8_t*)
    uint8_t buf_divx[4] = {'D', 'I', 'V', 'X'};
    uint8_t fcc_str_divx[5] = "DIVX";
    uint8_t fcc_str_xvid[5] = "XVID";
    if (!fourCC::check(buf_divx, fcc_str_divx)) {
        printf("Test check(buf, DIVX) failed\n");
        return 1;
    }
    if (fourCC::check(buf_divx, fcc_str_xvid)) {
        printf("Test check(buf, XVID) failed\n");
        return 1;
    }
    printf("Test check(uint8_t*, uint8_t*): passed\n");

    printf("All fourCC unit tests passed!\n");
    return 0;
}
