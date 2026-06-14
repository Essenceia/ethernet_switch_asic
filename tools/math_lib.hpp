#ifndef MATH_LIB_HPP
#define MATH_LIB_HPP

#include <stdint.h>

void init_bf16();
uint16_t bf16_remap_input(uint16_t x);

/* bfloat16 implementation follows the asic implementations
- no support for: subnormal, nan, inf
- round towards zero rounding */
uint16_t mul_bf16(uint16_t a, uint16_t b);

void print_bf16(uint16_t a);

void print_mul_bf16(uint16_t a, uint16_t b);
#endif // MATH_LIB_HPP
