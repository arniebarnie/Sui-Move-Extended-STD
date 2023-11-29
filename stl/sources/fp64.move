// SPDX-License-Identifier: MIT

module 0x0::fp64 {
//======================================================== IMPORTS ============================================================//
    use 0x0::u256::sqrt as sqrt_;
    use 0x1::fixed_point32::{get_raw_value, create_from_rational, FixedPoint32 as FP32};
//======================================================= ERROR CODES =========================================================//
    const EInvalidDivisor: u64 = 2;
//======================================================== CONSTANTS ==========================================================//
    const Q64: u8 = 64; // Number of integer or fractional bits in an FP64
    const Q32_TO_64: u8 = 32; // Number of bits to shift a FP32 to get a FP64
    const LAST_MASK: u128 = 0xFFFFFFFFFFFFFFFF; // Mask to get the last 64 bits of an integer
//========================================================= OBJECTS ===========================================================//
    // FP64 is a 64.64 fixed point number stored in a u128
    struct FP64 has copy, drop, store { 
        bits: u128
    }
//========================================================= METHODS ===========================================================//
    // New FP64 with value 0
    public fun zero(): FP64 {
        FP64 { bits: 0 }
    }
    // New FP64 from raw bits from a u128
    public fun fp64(bits: u128): FP64 {
        FP64 { bits }
    }
    // New FP64 from a u64 interpreted as an integer
    public fun int(x: u64): FP64 {
        FP64 { bits: (x as u128) << Q64 }
    }
    // New FP64 from x / y
    // x and y are u64 interpreted as integers
    // Aborts if x / y is too small to hold in a FP64
    public fun frac(x: u64, y: u64): FP64 {
        assert!(y != 0, EInvalidDivisor);
        let res = ((x as u128) << Q64) / (y as u128);
        FP64 { bits: res }
    }
    // New FP64 from FP32
    public fun fp32(x: FP32): FP64 {
        FP64 { bits: (get_raw_value(x) as u128) << Q32_TO_64 }
    }
    // Get bits of FP64
    public fun bits(x: FP64): u128 {
        x.bits
    }
    // Get center 64 bits of FP64
    public fun center(x: FP64): u64 {
        (((x.bits >> 32) & LAST_MASK) as u64)
    }
    // x + y
    public fun add(x: FP64, y: FP64): FP64 {
        FP64 { bits: x.bits + y.bits }
    }
    // x - y
    public fun sub(x: FP64, y: FP64): FP64 {
        FP64 { bits: x.bits - y.bits }
    }
    // x * y where x and y are FP64
    public fun mul(x: FP64, y: FP64): FP64 {
        FP64 { bits: ((((x.bits as u256) * (y.bits as u256)) >> Q64) as u128) }
    }
    // x / y where x and y are FP64
    public fun div(x: FP64, y: FP64): FP64 {
        FP64 { bits: ((((x.bits as u256) << Q64) / (y.bits as u256)) as u128) }
    }
    // x * y where x is an integer
    public fun prod(x: u64, y: FP64): u64 {
        (((x as u256) * (y.bits as u256)) >> Q64 as u64)
    }
    // x / y where x is an integer
    public fun quot(x: u64, y: FP64): u64 {
        ((((x as u128) << Q64) / y.bits) as u64)
    }
    public fun sqrt(x: FP64): FP64 {
        FP64 { bits: (sqrt_((x.bits as u256) << Q64) as u128) }
    }
//========================================================== TESTS ============================================================//
    #[test]
    fun test_zero() {
        assert!(bits(zero()) == 0, 1);
    }
    #[test]
    fun test_fp64() {
        assert!(bits(fp64(0)) == 0, 2);
        assert!(bits(fp64(2353)) == 2353, 3);
    }
    #[test]
    fun test_int() {
        assert!(bits(int(0)) == 0, 4);
        assert!(bits(int(2353)) == 2353 << Q64, 5);
    }
    #[test]
    fun test_frac() {
        assert!(bits(frac(56, 1)) == 56 << Q64, 6);
        assert!(bits(frac(56, 2)) == 28 << Q64, 7);
        assert!(bits(frac(56, 4)) == 14 << Q64, 9);
        assert!(bits(frac(1, 2)) == 1 << (Q64 - 1), 10);
        assert!(bits(frac(1, 8)) == 1 << (Q64 - 3), 11);
    }
    #[test]
    #[expected_failure]
    fun test_frac_fail_invalid_denominator() {
        frac(1, 0);
    }
    #[test]
    fun test_fp32() {
        assert!(bits(fp32(create_from_rational(1, 1))) == 1 << Q64, 12);
        assert!(bits(fp32(create_from_rational(9, 8))) == (1 << Q64) + (1 << (Q64 - 3)), 13);
    }
    #[test]
    fun test_bits() {
        assert!(bits(FP64 { bits: 0 }) == 0, 14);
        assert!(bits(FP64 { bits: 2353 }) == 2353, 15);
    }
    #[test]
    fun test_center() {
        assert!(center(FP64 { bits: 0 }) == 0, 16);
        assert!(center(int(1)) == get_raw_value(create_from_rational(1, 1)), 17);
        assert!(center(frac(873, 128)) == get_raw_value(create_from_rational(873, 128)), 18);
    }
    #[test]
    fun test_add() {
        assert!(bits(add(int(1), int(1))) == 2 << Q64, 19);
        assert!(bits(add(int(1), int(2))) == 3 << Q64, 20);
        assert!(bits(add(int(2), int(1))) == 3 << Q64, 21);
        assert!(bits(add(int(2), int(2))) == 4 << Q64, 22);
        assert!(bits(add(int(1), frac(1, 2))) == (1 << Q64) + (1 << (Q64 - 1)), 23);
        assert!(bits(add(frac(1, 2), int(1))) == (1 << Q64) + (1 << (Q64 - 1)), 24);
        assert!(bits(add(frac(1, 2), frac(1, 2))) == (1 << Q64), 25);
    }
    #[test]
    fun test_sub() {
        assert!(bits(sub(int(1), int(1))) == 0, 26);
        assert!(bits(sub(int(2), int(1))) == 1 << Q64, 27);
        assert!(bits(sub(int(2), int(2))) == 0, 28);
        assert!(bits(sub(int(1), frac(1, 2))) == 1 << (Q64 - 1), 29);
        assert!(bits(sub(frac(1, 2), frac(1, 2))) == 0, 30);
    }
    #[test]
    fun test_mul() {
        assert!(bits(mul(int(1), int(1))) == 1 << Q64, 31);
        assert!(bits(mul(int(2), int(1))) == 2 << Q64, 32);
        assert!(bits(mul(int(2), int(2))) == 4 << Q64, 33);
        assert!(bits(mul(int(1), frac(1, 2))) == 1 << (Q64 - 1), 34);
        assert!(bits(mul(frac(1, 2), int(1))) == 1 << (Q64 - 1), 35);
        assert!(bits(mul(frac(1, 2), frac(1, 2))) == 1 << (Q64 - 2), 36);
    }
    #[test]
    fun test_div() {
        assert!(bits(div(int(1), int(1))) == 1 << Q64, 37);
        assert!(bits(div(int(2), int(1))) == 2 << Q64, 38);
        assert!(bits(div(int(2), int(2))) == 1 << Q64, 39);
        assert!(bits(div(int(1), frac(1, 2))) == 2 << Q64, 40);
        assert!(bits(div(frac(1, 2), int(1))) == 1 << (Q64 - 1), 41);
        assert!(bits(div(frac(1, 2), frac(1, 2))) == 1 << Q64, 42);
        assert!(bits(div(int(1), int(2))) == 1 << (Q64 - 1), 43);
    }
    #[test]
    fun test_prod() {
        assert!(prod(1, int(1)) == 1, 44);
        assert!(prod(2, int(1)) == 2, 45);
        assert!(prod(2, int(2)) == 4, 46);
        assert!(prod(1, frac(1, 2)) == 0, 47);
        assert!(prod(2, frac(1, 2)) == 1, 48);
        assert!(prod(2, frac(1, 4)) == 0, 49);
        assert!(prod(16, frac(1, 8)) == 2, 50);
    }
    #[test]
    fun test_quot() {
        assert!(quot(1, int(1)) == 1, 51);
        assert!(quot(2, int(1)) == 2, 52);
        assert!(quot(2, int(2)) == 1, 53);
        assert!(quot(1, frac(1, 2)) == 2, 54);
        assert!(quot(2, frac(1, 2)) == 4, 55);
        assert!(quot(2, frac(1, 4)) == 8, 56);
        assert!(quot(16, frac(1, 8)) == 128, 57);
        assert!(quot(5, frac(5, 2)) == 2, 57);
    }
    #[test]
    fun test_sqrt() {
        assert!(bits(sqrt(int(1))) == 1 << Q64, 58);
        assert!(sqrt(int(9)) == int(3), 59);
        assert!(sqrt(frac(1, 16)) == frac(1, 4), 60);
    }
}