#include <stdint.h>

volatile int32_t matrix_checksum;

int main(void)
{
    int32_t A[4][4];
    int32_t B[4][4];
    int32_t C[4][4];
    int i, j, k;
    int32_t sum = 0;

    for (i = 0; i < 4; ++i) {
        for (j = 0; j < 4; ++j) {
            A[i][j] = (i + 1) * (j + 2) - 3;
            B[i][j] = (i == j) ? 3 : (i + j + 1);
            C[i][j] = 0;
        }
    }

    // Repeat the workload during power measurement.
    for (int rep = 0; rep < 32; ++rep) {
        for (i = 0; i < 4; ++i) {
            for (j = 0; j < 4; ++j) {
                int32_t acc = 0;
                for (k = 0; k < 4; ++k)
                    acc += A[i][k] * B[k][j];
                C[i][j] = acc + rep;
            }
        }
    }

    for (i = 0; i < 4; ++i)
        for (j = 0; j < 4; ++j)
            sum += C[i][j];

    matrix_checksum = sum;
    return (int)(sum & 0xff);
}
