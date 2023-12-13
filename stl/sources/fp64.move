// SPDX-License-Identifier: MIT

/// A `FP64` is a 64.64 bit fixed point number stored in a u128.
module 0x0::fp64 {
//======================================================== IMPORTS ============================================================//
    use 0x0::u256::sqrt as sqrt_;
    use 0x1::fixed_point32::{get_raw_value, FixedPoint32 as FP32};
//======================================================= ERROR CODES =========================================================//
    const EInvalidDivisor: u64 = 2;
//======================================================== CONSTANTS ==========================================================//
    const Q64: u8 = 64; // Number of integer or fractional bits in an FP64
    const Q32_TO_64: u8 = 32; // Number of bits to shift a FP32 to get a FP64
    const LAST_MASK: u128 = 0xFFFFFFFFFFFFFFFF; // Mask to get the last 64 bits of an integer
    const LAST_MASK_256: u256 = 0xFFFFFFFFFFFFFFFF; // Above constant as a u256
    const HALF: u128 = 1 << 63; // 1/2 in a FP64
//========================================================= OBJECTS ===========================================================//
    /// `FP64` is a 64.64 fixed point number stored in a u128
    struct FP64 has copy, drop, store { 
        bits: u128
    }
//========================================================= METHODS ===========================================================//
    /// Returns a new `FP64` of value 0.
    public fun zero(): FP64 {
        FP64 { bits: 0 }
    }
    /// Returns a `FP64` from raw bits from a u128.
    public fun fp64(bits: u128): FP64 {
        FP64 { bits }
    }
    /// Returns a new `FP64` from a u64 interpreted as an integer.
    public fun int(x: u64): FP64 {
        FP64 { bits: (x as u128) << Q64 }
    }
    /// Returns a new `FP64` from `x / y`.
    /// `x` and `y` are `u64` interpreted as integers.
    public fun frac(x: u64, y: u64): FP64 {
        assert!(y != 0, EInvalidDivisor);
        let res = ((x as u128) << Q64) / (y as u128);
        FP64 { bits: res }
    }
    /// Returns a new `FP64` from a `0x1::FixedPoint32`
    public fun fp32(x: FP32): FP64 {
        FP64 { bits: (get_raw_value(x) as u128) << Q32_TO_64 }
    }
    /// Returns bits of `x`
    public fun bits(x: FP64): u128 {
        x.bits
    }
    /// Returns center 64 bits of `x`
    public fun center(x: FP64): u64 {
        (((x.bits >> 32) & LAST_MASK) as u64)
    }
    /// Returns `x + y`
    public fun add(x: FP64, y: FP64): FP64 {
        FP64 { bits: x.bits + y.bits }
    }
    /// Returns `x - y`
    public fun sub(x: FP64, y: FP64): FP64 {
        FP64 { bits: x.bits - y.bits }
    }
    /// Returns `x * y` where `x` and `y` are `FP64`s
    public fun mul(x: FP64, y: FP64): FP64 {
        FP64 { bits: ((((x.bits as u256) * (y.bits as u256)) >> Q64) as u128) }
    }
    /// Returns `x / y` where `x` and `y` are `FP64`s
    public fun div(x: FP64, y: FP64): FP64 {
        FP64 { bits: ((((x.bits as u256) << Q64) / (y.bits as u256)) as u128) }
    }
    /// Returns `|x - y|`
    public fun diff(x: FP64, y: FP64): FP64 {
        if (x.bits > y.bits) FP64 { bits: x.bits - y.bits } else FP64 { bits: y.bits - x.bits }
    }
    /// Returns `x * y` where `x` is a `u64` interpreted as an integer
    public fun mul_u64(x: u64, y: FP64): u64 {
        (((x as u256) * (y.bits as u256)) >> Q64 as u64)
    }
    /// Returns `x * y` rounded up if the fractional part is nonzero, where `y` is a `u64` interpreted as an integer
    public fun mul_up(x: u64, y: FP64): u64 {
        let res = (x as u256) * (y.bits as u256);
        ((res >> Q64) as u64) + (if (res & LAST_MASK_256 == 0) 0 else 1)
    }
    /// Returns `x / y` where `x` is a `u64` interpreted as an integer
    public fun div_u64(x: u64, y: FP64): u64 {
        ((((x as u128) << Q64) / y.bits) as u64)
    }
    /// Returns `x / y` rounded up if the fractional part is nonzero, where `y` is a `u64` interpreted as an integer
    public fun div_up(x: u64, y: FP64): u64 {
        let x = (x as u256) << Q64;
        let y = (y.bits as u256);
        (x / y as u64) + (if (x % y == 0) 0 else 1)
    }
    /// Returns `sqrt(x)`
    public fun sqrt(x: FP64): FP64 {
        FP64 { bits: (sqrt_((x.bits as u256) << Q64) as u128) }
    }
    /// Returns `floor(x)`
    public fun floor(x: FP64): u64 {
        (x.bits >> Q64 as u64)
    }
    /// Returns `ceil(x)`
    public fun ceil(x: FP64): u64 {
        (x.bits >> Q64 as u64) + (if (x.bits & LAST_MASK == 0) 0 else 1)
    }
    /// Rounds `x` to nearest integer
    public fun round(x: FP64): u64 {
        (x.bits >> Q64 as u64) + (if (x.bits & HALF == 0) 0 else 1)
    }
    /// Returns true if `x == y` and false otherwise
    public fun eq(x: FP64, y: FP64): bool {
        x.bits == y.bits
    }
    /// Returns true if `x < y` and false otherwise
    public fun lt(x: FP64, y: FP64): bool {
        x.bits < y.bits
    }
    /// Returns true if `x <= y` and false otherwise
    public fun lte(x: FP64, y: FP64): bool {
        x.bits <= y.bits
    }
    /// Returns true if `x > y` and false otherwise
    public fun gt(x: FP64, y: FP64): bool {
        x.bits > y.bits
    }
    /// Returns true if `x >= y` and false otherwise
    public fun gte(x: FP64, y: FP64): bool {
        x.bits >= y.bits
    }
    /// Returns `min(x, y)`
    public fun min(x: FP64, y: FP64): FP64 {
        if (x.bits < y.bits) x else  y
    }
    /// Returns `max(x, y)`
    public fun max(x: FP64, y: FP64): FP64 {
        if (x.bits > y.bits) x else  y
    }
//========================================================== TESTS ============================================================//
    #[test_only]
    use 0x1::fixed_point32::create_from_rational;
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
    fun test_mul_u64() {
        assert!(mul_u64(1, int(1)) == 1, 44);
        assert!(mul_u64(2, int(1)) == 2, 45);
        assert!(mul_u64(2, int(2)) == 4, 46);
        assert!(mul_u64(1, frac(1, 2)) == 0, 47);
        assert!(mul_u64(2, frac(1, 2)) == 1, 48);
        assert!(mul_u64(2, frac(1, 4)) == 0, 49);
        assert!(mul_u64(16, frac(1, 8)) == 2, 50);
    }
    #[test]
    fun test_div_u64() {
        assert!(div_u64(1, int(1)) == 1, 51);
        assert!(div_u64(2, int(1)) == 2, 52);
        assert!(div_u64(2, int(2)) == 1, 53);
        assert!(div_u64(1, frac(1, 2)) == 2, 54);
        assert!(div_u64(2, frac(1, 2)) == 4, 55);
        assert!(div_u64(2, frac(1, 4)) == 8, 56);
        assert!(div_u64(16, frac(1, 8)) == 128, 57);
        assert!(div_u64(5, frac(5, 2)) == 2, 57);
    }
    #[test]
    fun test_sqrt() {
        assert!(bits(sqrt(int(1))) == 1 << Q64, 58);
        assert!(sqrt(int(9)) == int(3), 59);
        assert!(sqrt(frac(1, 16)) == frac(1, 4), 60);
    }
    #[test]
    fun test_ceil() {
        assert!(ceil(int(1)) == 1, 61);
        assert!(ceil(frac(1, 2)) == 1, 62);
        assert!(ceil(frac(25, 4)) == 7, 63);
        assert!(ceil(frac(40, 8)) == 5, 64);
    }
    #[test]
    fun test_floor() {
        assert!(floor(int(1)) == 1, 65);
        assert!(floor(frac(1, 2)) == 0, 66);
        assert!(floor(frac(25, 4)) == 6, 67);
        assert!(floor(frac(40, 8)) == 5, 68);
    }
    #[test]
    fun test_round() {
        assert!(round(int(1)) == 1, 69);
        assert!(round(frac(1, 2)) == 1, 70);
        assert!(round(frac(25, 4)) == 6, 71);
        assert!(round(frac(40, 8)) == 5, 72);
        assert!(round(frac(45, 8)) == 6, 73);
    }
    #[test]
    fun test_mul_up() {
        assert!(mul_up(1, int(1)) == 1, 74);
        assert!(mul_up(2, int(1)) == 2, 75);
        assert!(mul_up(2, int(2)) == 4, 76);
        assert!(mul_up(1, frac(1, 2)) == 1, 77);
        assert!(mul_up(2, frac(1, 2)) == 1, 78);
        assert!(mul_up(2, frac(1, 4)) == 1, 79);
        assert!(mul_up(17, frac(1, 8)) == 3, 80);
    }
    #[test]
    fun test_div_up() {
        assert!(div_up(1, int(1)) == 1, 81);
        assert!(div_up(2, int(1)) == 2, 82);
        assert!(div_up(2, int(2)) == 1, 83);
        assert!(div_up(1, frac(1, 2)) == 2, 84);
        assert!(div_up(2, frac(1, 2)) == 4, 85);
        assert!(div_up(2, frac(6, 4)) == 2, 86);
        assert!(div_up(16, frac(1, 8)) == 128, 87);
        assert!(div_up(5, frac(5, 2)) == 2, 88);
    }
}