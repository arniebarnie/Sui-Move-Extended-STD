// SPDX-License-Identifier: MIT

/// An `I64` is a signed 64-bit integer.
module 0x0::i64 {
//======================================================= ERROR CODES =========================================================//
    const EOverflow: u64 = 1;
//======================================================== CONSTANTS ==========================================================//
    const U63: u8 = 63; // Bits allocated to value of i64
    const MAX_I64: u64 = (1 << 63) - 1; // Maximum absolute value of i64
    const NEG_VAL: u64 = (1 << 63); // i64 with value of 0 but sign bit flipped on
    const SET_ABS: u64 = 0x8000000000000000 ^ 0xFFFFFFFFFFFFFFFF; // Mask to set sign bit off
//========================================================= OBJECTS ===========================================================//
    /// First bit stores sign, and remaining (63 bits) store value
    struct I64 has copy, drop, store { 
        bits: u64 
    }
//========================================================= METHODS ===========================================================//
    /// Returns `I64` of value 0.
    public fun zero(): I64 { 
        I64 { bits: 0 } 
    }
    /// Returns `I64` of value `x`.
    public fun i64(x: u64): I64 {
        // Make sure that first bit is free to hold sign
        assert!(x < MAX_I64, EOverflow);
        I64 { bits: x }
    }
    /// Returns `x` as a `u64`.
    /// Aborts if `x < 0`.
    public fun u63(x: I64): u64 {
        // Make sure that x is positive
        assert!(x.bits < NEG_VAL, EOverflow);
        x.bits
    }
    // Splits `x` into sign and absolute value.
    public fun split(x: I64): (bool, u64) {
        (x.bits < NEG_VAL, x.bits & SET_ABS)
    }
    // Returns raw bits of `x`.
    public fun bits(x: I64): u64 { 
        x.bits 
    }
    // Returns `max(0, x)` as a `u64`.
    public fun plus(x: I64): u64 {
        // If x is negative return 0 else value of x
        if (x.bits > NEG_VAL) 0 else x.bits
    }
    // Returns `max(0, -x)` as a `u64`.
    public fun minus(x: I64): u64 {
        // If x is positive return 0 else value of x
        if (x.bits < NEG_VAL) 0 else (x.bits & SET_ABS)
    }
    // Returns true if `x >= 0` and false otherwise.
    public fun sign(x: I64): bool { 
        x.bits < NEG_VAL 
    }
    // Returns `-x`
    public fun neg(x: I64): I64 {
        // If x is 0 don't flip sign bit
        I64 { bits: (if (x.bits != 0) (x.bits ^ NEG_VAL) else 0) } 
    }
    // Returns `-|x|`
    public fun force(x: I64): I64 {
        // If x is 0 don't flip sign bit
        I64 { bits: (if (x.bits != 0) (x.bits | NEG_VAL) else 0) }
    }
    // Returns `|x|`
    public fun abs(x: I64): I64 {
        // Set sign bit off
        I64 { bits: (x.bits & SET_ABS) } 
    }
    // Returns `x == y`
    public fun eq(x: I64, y: I64): bool { 
        x.bits == y.bits 
    }
    // Returns `x < y`
    public fun lt(x: I64, y: I64): bool {
        // Sign of x
        let x_neg = x.bits > NEG_VAL;
        // Sign of y
        let y_neg = y.bits > NEG_VAL;

        // If x and y have different signs, see which is negative
        if (x_neg != y_neg) x_neg
        else if (x_neg) (x.bits > y.bits)
        else (x.bits < y.bits)
    }
    // Returns `x <= y`
    public fun lte(x: I64, y: I64): bool {
        // Sign of x
        let x_neg = x.bits > NEG_VAL;
        // Sign of y
        let y_neg = y.bits > NEG_VAL;

        // If x and y have different signs, see which is negative
        if (x_neg != y_neg) x_neg
        else if (x_neg) (x.bits >= y.bits)
        else (x.bits <= y.bits)
    }
    // Returns `x > y`
    public fun gt(x: I64, y: I64): bool {
        // Sign of x
        let x_pos = x.bits < NEG_VAL;
        // Sign of y
        let y_pos = y.bits < NEG_VAL;

        // If x and y have different signs, see which is negative
        if (x_pos != y_pos) x_pos
        else if (x_pos) (x.bits > y.bits)
        else (x.bits < y.bits)
    }
    // Returns `x >= y`
    public fun gte(x: I64, y: I64): bool {
        // Sign of x
        let x_pos = x.bits < NEG_VAL;
        // Sign of y
        let y_pos = y.bits < NEG_VAL;

        // If x and y have different signs, see which is negative
        if (x_pos != y_pos) x_pos
        else if (x_pos) (x.bits >= y.bits)
        else (x.bits <= y.bits)
    }
    // Returns `max(x, y)`
    public fun max(x: I64, y: I64): I64 {
        // Sign of x
        let x_neg = x.bits > NEG_VAL;
        // Sign of y
        let y_neg = y.bits > NEG_VAL;

        if (x_neg != y_neg) (if (x_neg) y else x)
        else if (x_neg) (if (x.bits < y.bits) x else y)
        else (if (x.bits > y.bits) x else y)
    }
    // Returns `min(x, y)`
    public fun min(x: I64, y: I64): I64 {
        // Sign of x
        let x_neg = x.bits > NEG_VAL;
        // Sign of y
        let y_neg = y.bits > NEG_VAL;

        if (x_neg != y_neg) (if (x_neg) x else y)
        else if (x_neg) (if (x.bits > y.bits) x else y)
        else (if (x.bits < y.bits) x else y)
    }
    // Returns `x + y`
    public fun add(x: I64, y: I64): I64 {
        let x = x.bits;
        let y = y.bits;
        // Check if x is positive
        if (x < NEG_VAL) {
            // Check if y is positive
            if (y < NEG_VAL) {
                assert!(x + y < NEG_VAL, EOverflow);
                I64 { bits: x + y } 
            } else I64 { bits: if ((y & SET_ABS) > x) (y - x) else (x - (y & SET_ABS)) }
        } else {
            // Check if y is positive
            // If value of x > value of y then x - y else y - value of x
            if (y < NEG_VAL) I64 { bits: if ((x & SET_ABS) > y) (x - y) else (y - (x & SET_ABS)) }
            else I64 { bits: x + (y & SET_ABS) }
        }
    }
    // Returns `x - y`
    public fun sub(x: I64, y: I64): I64 {
        let x = x.bits;
        let y = y.bits;
        // Check if x is positive
        if (x < NEG_VAL) {
            // Check if y is positive
            if (y < NEG_VAL) I64 { bits: if (x >= y) (x - y) else ((y ^ NEG_VAL) - x) }
            else { 
                let res = x + (y & SET_ABS);
                assert!(res < NEG_VAL, EOverflow);
                I64 { bits: res }
            }
        } else {
            // Check if y is positive
            if (y < NEG_VAL) I64 { bits: x + y }
            else I64 { bits: if (y >= x) (y - x) else NEG_VAL + (x - y) }
        }
    }
    // Returns `x * y`
    public fun mul(x: I64, y: I64): I64 {
        let x = x.bits;
        let y = y.bits;
        if (x == 0 || y == 0) I64 { bits: 0 }
        else {
            // |x| * |y|
            let res = (x & SET_ABS) * (y & SET_ABS);
            // Make sure that res does not reach the first bit
            assert!(res < NEG_VAL, EOverflow);
            // Negate res if sign(x) != sign(y)
            I64 { bits: res + (if ((x >> U63) == (y >> U63)) 0 else NEG_VAL) }
        }
    }
    // Returns `x / y`
    public fun div(x: I64, y: I64): I64 {
        let x = x.bits;
        let y = y.bits;
        if (x == 0) I64 { bits: 0 }
        // Negate x / y if sign(x) != sign(y)
        else I64 { bits: ((x & SET_ABS) / (y & SET_ABS)) + (if ((x >> U63) == (y >> U63)) 0 else NEG_VAL) }
    }
    // Returns `|x - y|`
    public fun diff(x: I64, y: I64): I64 {
        let x = x.bits;
        let y = y.bits;
        if (x < NEG_VAL) {
            if (y < NEG_VAL) I64 { bits: if (x > y) (x - y) else (y - x)}
            else {
                let res = x + (y & SET_ABS);
                assert!(res < NEG_VAL, EOverflow);
                I64 { bits: res }
            }
        } else {
            if (y < NEG_VAL) { 
                let res = y + (x & SET_ABS);
                assert!(res < NEG_VAL, EOverflow);
                I64 { bits: res }
            }
            else I64 { bits: if (x > y) ((x - y) & SET_ABS) else ((y - x) & SET_ABS) }
        }
    }
    // Returns `x^y`
    public fun pow(x: I64, y: u8): I64 {
        let sgn = (x.bits >> U63) * ((y % 2) as u64) * NEG_VAL;
        let x_val = x.bits & SET_ABS;
        if (y == 0) return I64 { bits: 1 };

        while (y & 1 == 0) {
            x_val = x_val * x_val;
            y = y >> 1;
        };
        if (y == 1) return I64 { bits: x_val + sgn };

        let res = x_val;
        while (y > 1) {
            y = y >> 1;
            x_val = x_val * x_val;
            if (y & 1 == 1) res = res * x_val;
        };
        I64 { bits: res + sgn }
    }
//========================================================== TESTS ============================================================//
    #[test]
    fun zero_test() {
        assert!(zero() == I64 { bits: 0 }, 1);
    }
    #[test]
    fun i64_test() {
        assert!(i64(0) == I64 { bits: 0 }, 1);
        assert!(i64(5) == I64 { bits: 5 }, 2);
    }
    #[test]
    #[expected_failure]
    fun i64_test_fail() {
        i64(MAX_I64 + 10);
    }
    #[test]
    fun u63_test() {
        assert!(u63(I64 { bits: 0 }) == 0, 1);
        assert!(u63(I64 { bits: 5 }) == 5, 2);
    }
    #[test]
    #[expected_failure]
    fun u63_test_fail() {
        u63(I64 { bits: NEG_VAL + 10 });
    }
    #[test]
    fun split_test() {
        let (sign, val) = split(I64 { bits: 0 });
        assert!(sign == true && val == 0, 1);
        let (sign, val) = split(I64 { bits: 5 });
        assert!(sign == true && val == 5, 2);
        let (sign, val) = split(I64 { bits: NEG_VAL + 10 });
        assert!(sign == false && val == 10, 3);
    }
    #[test]
    fun bits_test() {
        assert!(bits(I64 { bits: 0 }) == 0, 1);
        assert!(bits(I64 { bits: 5 }) == 5, 2);
        assert!(bits(I64 { bits: NEG_VAL + 10 }) == NEG_VAL + 10, 3);
    }
    #[test]
    fun plus_test() {
        assert!(plus(I64 { bits: 0 }) == 0, 1);
        assert!(plus(I64 { bits: 5 }) == 5, 2);
        assert!(plus(I64 { bits: NEG_VAL + 10 }) == 0, 3);
    }
    #[test]
    fun minus_test() {
        assert!(minus(I64 { bits: 0 }) == 0, 1);
        assert!(minus(I64 { bits: 5 }) == 0, 2);
        assert!(minus(I64 { bits: NEG_VAL + 10 }) == 10, 3);
    }
    #[test]
    fun sign_test() {
        assert!(sign(I64 { bits: 0 }) == true, 1);
        assert!(sign(I64 { bits: 5 }) == true, 2);
        assert!(sign(I64 { bits: NEG_VAL + 10 }) == false, 3);
    }
    #[test]
    fun neg_test() {
        assert!(neg(I64 { bits: 0 }) == I64 { bits: 0 }, 1);
        assert!(neg(I64 { bits: 5 }) == I64 { bits: NEG_VAL + 5 }, 2);
        assert!(neg(I64 { bits: NEG_VAL + 10 }) == I64 { bits: 10 }, 3);
    }
    #[test]
    fun force_test() {
        assert!(force(I64 { bits: 0 }) == I64 { bits: 0 }, 1);
        assert!(force(I64 { bits: 5 }) == I64 { bits: NEG_VAL + 5 }, 2);
        assert!(force(I64 { bits: NEG_VAL + 10 }) == I64 { bits: NEG_VAL + 10 }, 3);
    }
    #[test]
    fun abs_test() {
        assert!(abs(I64 { bits: 0 }) == I64 { bits: 0 }, 1);
        assert!(abs(I64 { bits: 5 }) == I64 { bits: 5 }, 2);
        assert!(abs(I64 { bits: NEG_VAL + 10 }) == I64 { bits: 10 }, 3);
    }
    #[test]
    fun eq_test() {
        assert!(eq(I64 { bits: 0 }, I64 { bits: 0 }) == true, 1);
        assert!(eq(I64 { bits: 5 }, I64 { bits: 5 }) == true, 2);
        assert!(eq(I64 { bits: 5 }, I64 { bits: 10 }) == false, 3);
        assert!(eq(I64 { bits: NEG_VAL + 10 }, I64 { bits: 10 }) == false, 4);
    }
    #[test]
    fun lt_test() {
        assert!(lt(I64 { bits: 0 }, I64 { bits: 0 }) == false, 1);
        assert!(lt(I64 { bits: 5 }, I64 { bits: 5 }) == false, 2);
        assert!(lt(I64 { bits: NEG_VAL + 5 }, I64 { bits: NEG_VAL + 5 }) == false, 3);
        assert!(lt(I64 { bits: NEG_VAL + 5 }, I64 { bits: NEG_VAL + 10 }) == false, 4);
        assert!(lt(I64 { bits: 5 }, I64 { bits: 10 }) == true, 5);
        assert!(lt(I64 { bits: NEG_VAL + 10 }, I64 { bits: NEG_VAL + 5 }) == true, 6);
    }
    #[test]
    fun lte_test() {
        assert!(lte(I64 { bits: 0 }, I64 { bits: 0 }) == true, 1);
        assert!(lte(I64 { bits: 5 }, I64 { bits: 5 }) == true, 2);
        assert!(lte(I64 { bits: NEG_VAL + 5 }, I64 { bits: NEG_VAL + 5 }) == true, 3);
        assert!(lte(I64 { bits: NEG_VAL + 5 }, I64 { bits: NEG_VAL + 10 }) == false, 4);
        assert!(lte(I64 { bits: 5 }, I64 { bits: 10 }) == true, 5);
        assert!(lte(I64 { bits: NEG_VAL + 10 }, I64 { bits: NEG_VAL + 5 }) == true, 6);
    }
    #[test]
    fun gt_test() {
        assert!(gt(I64 { bits: 0 }, I64 { bits: 0 }) == false, 1);
        assert!(gt(I64 { bits: 5 }, I64 { bits: 5 }) == false, 2);
        assert!(gt(I64 { bits: NEG_VAL + 5 }, I64 { bits: NEG_VAL + 5 }) == false, 3);
        assert!(gt(I64 { bits: NEG_VAL + 5 }, I64 { bits: NEG_VAL + 10 }) == true, 4);
        assert!(gt(I64 { bits: 5 }, I64 { bits: 10 }) == false, 5);
        assert!(gt(I64 { bits: NEG_VAL + 10 }, I64 { bits: NEG_VAL + 5 }) == false, 6);
    }
    #[test]
    fun gte_test() {
        assert!(gte(I64 { bits: 0 }, I64 { bits: 0 }) == true, 1);
        assert!(gte(I64 { bits: 5 }, I64 { bits: 5 }) == true, 2);
        assert!(gte(I64 { bits: NEG_VAL + 5 }, I64 { bits: NEG_VAL + 5 }) == true, 3);
        assert!(gte(I64 { bits: NEG_VAL + 5 }, I64 { bits: NEG_VAL + 10 }) == true, 4);
        assert!(gte(I64 { bits: 5 }, I64 { bits: 10 }) == false, 5);
        assert!(gte(I64 { bits: NEG_VAL + 10 }, I64 { bits: NEG_VAL + 5 }) == false, 6);
    }
    #[test]
    fun max_test() {
        assert!(max(I64 { bits: 0 }, I64 { bits: 0 }) == I64 { bits: 0 }, 1);
        assert!(max(I64 { bits: 5 }, I64 { bits: 5 }) == I64 { bits: 5 }, 2);
        assert!(max(I64 { bits: NEG_VAL + 5 }, I64 { bits: NEG_VAL + 5 }) == I64 { bits: NEG_VAL + 5 }, 3);
        assert!(max(I64 { bits: NEG_VAL + 5 }, I64 { bits: NEG_VAL + 10 }) == I64 { bits: NEG_VAL + 5 }, 4);
        assert!(max(I64 { bits: 5 }, I64 { bits: 10 }) == I64 { bits: 10 }, 5);
        assert!(max(I64 { bits: 10 }, I64 { bits: 5 }) == I64 { bits: 10 }, 6);
        assert!(max(I64 { bits: NEG_VAL + 10 }, I64 { bits: NEG_VAL + 5 }) == I64 { bits: NEG_VAL + 5 }, 7);
    }
    #[test]
    fun min_test() {
        assert!(min(I64 { bits: 0 }, I64 { bits: 0 }) == I64 { bits: 0 }, 1);
        assert!(min(I64 { bits: 5 }, I64 { bits: 5 }) == I64 { bits: 5 }, 2);
        assert!(min(I64 { bits: NEG_VAL + 5 }, I64 { bits: NEG_VAL + 5 }) == I64 { bits: NEG_VAL + 5 }, 3);
        assert!(min(I64 { bits: NEG_VAL + 5 }, I64 { bits: NEG_VAL + 10 }) == I64 { bits: NEG_VAL + 10 }, 4);
        assert!(min(I64 { bits: 5 }, I64 { bits: 10 }) == I64 { bits: 5 }, 5);
        assert!(min(I64 { bits: 10 }, I64 { bits: 5 }) == I64 { bits: 5 }, 6);
        assert!(min(I64 { bits: NEG_VAL + 10 }, I64 { bits: NEG_VAL + 5 }) == I64 { bits: NEG_VAL + 10 }, 7);
    }
    #[test]
    fun add_test() {
        assert!(add(I64 { bits: 0 }, I64 { bits: 0 }) == I64 { bits: 0 }, 1);
        assert!(add(I64 { bits: 5 }, I64 { bits: 5 }) == I64 { bits: 10 }, 2);
        assert!(add(I64 { bits: NEG_VAL + 5 }, I64 { bits: NEG_VAL + 5 }) == I64 { bits: NEG_VAL + 10 }, 3);
        assert!(add(I64 { bits: NEG_VAL + 5 }, I64 { bits: NEG_VAL + 10 }) == I64 { bits: NEG_VAL + 15 }, 4);
        assert!(add(I64 { bits: 5 }, I64 { bits: 10 }) == I64 { bits: 15 }, 5);
        assert!(add(I64 { bits: 10 }, I64 { bits: 5 }) == I64 { bits: 15 }, 6);
        assert!(add(I64 { bits: NEG_VAL + 10 }, I64 { bits: NEG_VAL + 5 }) == I64 { bits: NEG_VAL + 15 }, 7);
        assert!(add(I64 { bits: 5 }, I64 { bits: NEG_VAL + 5 }) == I64 { bits: 0 }, 8);
        assert!(add(I64 { bits: NEG_VAL + 5 }, I64 { bits: 5 }) == I64 { bits: 0 }, 9);
    }
    #[test]
    #[expected_failure]
    fun add_test_fail_1() {
        add(I64 { bits: MAX_I64 }, I64 { bits: 1 });
    }
    #[test]
    #[expected_failure]
    fun add_test_fail_2() {
        add(I64 { bits: NEG_VAL + MAX_I64 }, I64 { bits: NEG_VAL + 1 });
    }
    #[test]
    fun sub_test() {
        assert!(sub(I64 { bits: 0 }, I64 { bits: 0 }) == I64 { bits: 0 }, 1);
        assert!(sub(I64 { bits: 5 }, I64 { bits: 5 }) == I64 { bits: 0 }, 2);
        assert!(sub(I64 { bits: NEG_VAL + 5 }, I64 { bits: NEG_VAL + 5 }) == I64 { bits: 0 }, 3);
        assert!(sub(I64 { bits: NEG_VAL + 5 }, I64 { bits: NEG_VAL + 10 }) == I64 { bits: 5 }, 4);
        assert!(sub(I64 { bits: 5 }, I64 { bits: 10 }) == I64 { bits: NEG_VAL + 5 }, 5);
        assert!(sub(I64 { bits: 10 }, I64 { bits: 5 }) == I64 { bits: 5 }, 6);
        assert!(sub(I64 { bits: NEG_VAL + 10 }, I64 { bits: NEG_VAL + 5 }) == I64 { bits: NEG_VAL + 5 }, 7);
    }
    #[test]
    #[expected_failure]
    fun sub_test_fail_1() {
        sub(I64 { bits: NEG_VAL + MAX_I64 }, I64 { bits: 1 });
    }
    #[test]
    #[expected_failure]
    fun sub_test_fail_2() {
        sub(I64 { bits: MAX_I64 }, I64 { bits: NEG_VAL + 1 });
    }
    #[test]
    fun mul_test() {
        assert!(mul(I64 { bits: 0 }, I64 { bits: 0 }) == I64 { bits: 0 }, 1);
        assert!(mul(I64 { bits: 5 }, I64 { bits: 5 }) == I64 { bits: 25 }, 2);
        assert!(mul(I64 { bits: NEG_VAL + 5 }, I64 { bits: NEG_VAL + 5 }) == I64 { bits: 25 }, 3);
        assert!(mul(I64 { bits: NEG_VAL + 5 }, I64 { bits: NEG_VAL + 10 }) == I64 { bits: 50 }, 4);
        assert!(mul(I64 { bits: 5 }, I64 { bits: 10 }) == I64 { bits: 50 }, 5);
        assert!(mul(I64 { bits: 10 }, I64 { bits: 5 }) == I64 { bits: 50 }, 6);
        assert!(mul(I64 { bits: NEG_VAL + 10 }, I64 { bits: NEG_VAL + 5 }) == I64 { bits: 50 }, 7);
        assert!(mul(I64 { bits: 10 }, I64 { bits: NEG_VAL + 5 }) == I64 { bits: NEG_VAL + 50 }, 8);
        assert!(mul(I64 { bits: NEG_VAL + 10 }, I64 { bits: 5 }) == I64 { bits: NEG_VAL + 50 }, 9);
    }
    #[test]
    #[expected_failure]
    fun mul_test_fail_1() {
        mul(I64 { bits: MAX_I64 - 1 }, I64 { bits: 2 });
    }
    #[test]
    #[expected_failure]
    fun mul_test_fail_2() {
        mul(I64 { bits: NEG_VAL + MAX_I64 - 1 }, I64 { bits: 2 });
    }
    #[test]
    #[expected_failure]
    fun mul_test_fail_3() {
        mul(I64 { bits: MAX_I64 - 1 }, I64 { bits: NEG_VAL + 2 });
    }
    #[test]
    #[expected_failure]
    fun mul_test_fail_4() {
        mul(I64 { bits: NEG_VAL + MAX_I64 - 1 }, I64 { bits: NEG_VAL + 2 });
    }
    #[test]
    fun div_test() {
        assert!(div(I64 { bits: 0 }, I64 { bits: 5 }) == I64 { bits: 0 }, 1);
        assert!(div(I64 { bits: 5 }, I64 { bits: 5 }) == I64 { bits: 1 }, 2);
        assert!(div(I64 { bits: NEG_VAL + 5 }, I64 { bits: NEG_VAL + 5 }) == I64 { bits: 1 }, 3);
        assert!(div(I64 { bits: NEG_VAL + 5 }, I64 { bits: NEG_VAL + 10 }) == I64 { bits: 0 }, 4);
        assert!(div(I64 { bits: 5 }, I64 { bits: 10 }) == I64 { bits: 0 }, 5);
        assert!(div(I64 { bits: 10 }, I64 { bits: 5 }) == I64 { bits: 2 }, 6);
        assert!(div(I64 { bits: NEG_VAL + 10 }, I64 { bits: NEG_VAL + 5 }) == I64 { bits: 2 }, 7);
        assert!(div(I64 { bits: 10 }, I64 { bits: NEG_VAL + 5 }) == I64 { bits: NEG_VAL + 2 }, 8);
        assert!(div(I64 { bits: NEG_VAL + 10 }, I64 { bits: 5 }) == I64 { bits: NEG_VAL + 2 }, 9);
    }
    #[test]
    #[expected_failure]
    fun div_test_fail_1() {
        div(I64 { bits: 5 }, I64 { bits: 0 });
    }
    #[test]
    #[expected_failure]
    fun div_test_fail_2() {
        div(I64 { bits: NEG_VAL + 5 }, I64 { bits: 0 });
    }
    #[test]
    fun diff_test() {
        assert!(diff(I64 { bits: 0 }, I64 { bits: 0 }) == I64 { bits: 0 }, 1);
        assert!(diff(I64 { bits: 5 }, I64 { bits: 5 }) == I64 { bits: 0 }, 2);
        assert!(diff(I64 { bits: NEG_VAL + 5 }, I64 { bits: NEG_VAL + 5 }) == I64 { bits: 0 }, 3);
        assert!(diff(I64 { bits: NEG_VAL + 5 }, I64 { bits: NEG_VAL + 10 }) == I64 { bits: 5 }, 4);
        assert!(diff(I64 { bits: 5 }, I64 { bits: 10 }) == I64 { bits: 5 }, 5);
        assert!(diff(I64 { bits: 10 }, I64 { bits: 5 }) == I64 { bits: 5 }, 6);
        assert!(diff(I64 { bits: NEG_VAL + 10 }, I64 { bits: NEG_VAL + 5 }) == I64 { bits: 5 }, 7);
    }
    #[test]
    #[expected_failure]
    fun diff_test_fail_1() {
        diff(I64 { bits: MAX_I64 }, I64 { bits: NEG_VAL + 1 });
    }
    #[test]
    #[expected_failure]
    fun diff_test_fail_2() {
        diff(I64 { bits: NEG_VAL + MAX_I64 }, I64 { bits: 1 });
    }
    #[test]
    fun pow_test() {
        assert!(pow(I64 { bits: 0 }, 0) == I64 { bits: 1 }, 1);
        assert!(pow(I64 { bits: 0 }, 1) == I64 { bits: 0 }, 2);
        assert!(pow(I64 { bits: 5 }, 0) == I64 { bits: 1 }, 3);
        assert!(pow(I64 { bits: 5 }, 2) == I64 { bits: 25 }, 4);
        assert!(pow(I64 { bits: NEG_VAL + 25 }, 3) == I64 { bits: NEG_VAL + 15625 }, 5);
        assert!(pow(I64 { bits: NEG_VAL + 25 }, 0) == I64 { bits: 1 }, 6);
    }
}