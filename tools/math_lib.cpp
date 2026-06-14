#include "math_lib.hpp"

#include <cmath> 
#include <iostream> 
#include <cfenv>
#include <iomanip>
#include <cassert>

#include <stdfloat>
#if __STDCPP_BFLOAT16_T__ != 1
    #error "bfloat16 type required"
#endif

#define IS_SUBNORMAL(x) (!(isnormal(x) | isnan(x) | isinf(x) | (x == 0e0bf16)))
#define BF16_DEFAULT_VAL 0e0bf16

using namespace std; 

typedef union {
	uint16_t u;
	bfloat16_t f;
} u16_u;
static_assert(sizeof(uint16_t) == sizeof(bfloat16_t));

void init_bf16(){
	fesetround(FE_TOWARDZERO);
}

bfloat16_t _subnormal_to_zero(bfloat16_t x){
	if IS_SUBNORMAL(x) {
		bool pos = !signbit(x);
#ifdef DEBUG
		cout << "rounding subnormal to "<< (pos?"+":"-") <<"0.0 from " << scientific << x << " [normal:"<<
		isnormal(x) << ", nan:"<< isnan(x) << ", inf:"<< isinf(x) << "]" << endl;
#endif
		if (pos) x = 0e0bf16;
		else x = -0e0bf16; // because -0 is a thing I want to handle
	}
	return x;
};

bfloat16_t expected_hw_result(bfloat16_t x){
	if IS_SUBNORMAL(x) {
		bool pos = !signbit(x);
#ifdef DEBUG
		cout << "rounding subnormal to "<< (pos?"+":"-") <<"0.0 from " << scientific << x << " [normal:"<<
		isnormal(x) << ", nan:"<< isnan(x) << ", inf:"<< isinf(x) << "]" << endl;
#endif
		if (pos) x = 0e0bf16;
		else x = -0e0bf16; // because -0 is a thing I want to handle
	}	
	assert(!(isnan(x) || isinf(x)));
	return x;
};

uint16_t mul_bf16(uint16_t a, uint16_t b){
	u16_u ua, ub, uc; 
	ua.u = a;
	ub.u = b; 
	
	// input should not be subnormal
	assert((IS_SUBNORMAL(a)|| isnan(a) || isinf(a)) == false && "Unexpected subnormal/inf/nan input on a");
	assert((IS_SUBNORMAL(b)|| isnan(b) || isinf(b)) == false && "Unexpected subnormal/inf/nan input on b");

	uc.f = ua.f * ub.f; 
	
	// hardware implementation rounds subnormals to 0 and set expected NaN
	uc.f = expected_hw_result(uc.f);

	return uc.u;
}

void print_bf16(uint16_t a){
	u16_u ua; 
	ua.u = a; 
	cout << scientific << ua.f; 
}

// format expected input, remove : 
// inf
// nan
// subnormals
uint16_t bf16_remap_input(uint16_t x){
	u16_u ux = {.u = x}; 
	ux.f = _subnormal_to_zero(ux.f);
	if (isnan(ux.f) || isinf(ux.f)) ux.f = BF16_DEFAULT_VAL;
	return ux.u; 
}


