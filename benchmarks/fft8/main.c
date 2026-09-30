#include <stdint.h>

// Eight-point fixed-point FFT. Twiddle factors use Q15.
volatile int32_t fft_checksum;

typedef struct { int32_t r, i; } cpx;

static cpx cmul_q15(cpx a, cpx b)
{
    int64_t rr = (int64_t)a.r * b.r - (int64_t)a.i * b.i;
    int64_t ii = (int64_t)a.r * b.i + (int64_t)a.i * b.r;
    cpx y;
    y.r = (int32_t)(rr >> 15);
    y.i = (int32_t)(ii >> 15);
    return y;
}

static void bit_reverse_8(cpx x[8])
{
    cpx t;
    t=x[1]; x[1]=x[4]; x[4]=t;
    t=x[3]; x[3]=x[6]; x[6]=t;
}

static void fft8(cpx x[8])
{
    cpx W[4];
    // exp(-j*2*pi*k/8) in Q15: 1, sqrt(1/2)-j sqrt(1/2), -j, ...
    W[0].r=32767; W[0].i=0;
    W[1].r=23170; W[1].i=-23170;
    W[2].r=0;     W[2].i=-32768;
    W[3].r=-23170;W[3].i=-23170;

    bit_reverse_8(x);
    for (int len=2; len<=8; len<<=1) {
        int half=len>>1;
        int step=8/len;
        for (int base=0; base<8; base+=len) {
            for (int j=0; j<half; ++j) {
                cpx t=cmul_q15(x[base+j+half], W[j*step]);
                cpx u=x[base+j];
                x[base+j].r      = u.r+t.r;
                x[base+j].i      = u.i+t.i;
                x[base+j+half].r = u.r-t.r;
                x[base+j+half].i = u.i-t.i;
            }
        }
    }
}

int main(void)
{
    cpx x[8];
    int32_t checksum=0;
    for (int rep=0; rep<32; ++rep) {
        for (int n=0; n<8; ++n) {
            x[n].r = ((n+1)*(rep+3)*257) & 0x3fff;
            x[n].i = ((n*37)-(rep*19)) & 0x1fff;
        }
        fft8(x);
        for (int n=0; n<8; ++n)
            checksum += x[n].r ^ x[n].i;
    }
    fft_checksum=checksum;
    return (int)(checksum & 0xff);
}
