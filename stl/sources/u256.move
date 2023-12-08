// SPDX-License-Identifier: MIT

/// Mathematical functions for `u256`s
module 0x0::u256 {
//========================================================= METHODS ===========================================================//
    /// `max(1, x)`
    public fun norm(x: u256): u256 { 
        if (x == 0) 1 else x
    }
    /// `min(x, y)`
    public fun min(x: u256, y: u256): u256 { 
        if (x < y) x else y 
    }
    /// `max(x, y)`
    public fun max(x: u256, y: u256): u256 { 
        if (x > y) x else y 
    }
    /// `|x - y|`
    public fun diff(x: u256, y: u256): u256 {
        if (x > y) (x - y) else (y - x)
    }
    /// `x^y`
    public fun pow(x: u256, y: u8): u256 {
        if (y == 0) return 1;

        while (y & 1 == 0) {
            x = x * x;
            y = y >> 1;
        };
        if (y == 1) return x;

        let res = x;
        while (y > 1) {
            y = y >> 1;
            x = x * x;
            if (y & 1 == 1) res = res * x;
        };
        res
    }
    /// `sqrt(x)` => EIP 7054
    public fun sqrt(x: u256): u256 {
        if (x == 0) {
            return 0
        };
        let a = x;

        let result = 1u256;
        if (x >> 128 > 0) {
            x = x >> 128;
            result = result << 64;
        };
        if (x >> 64 > 0) {
            x = x >> 64;
            result = result << 32;
        };
        if (x >> 32 > 0) {
            x = x >> 32;
            result = result << 16;
        };
        if (x >> 16 > 0) {
            x = x >> 16;
            result = result << 8;
        };
        if (x >> 8 > 0) {
            x = x >> 8;
            result = result << 4;
        };
        if (x >> 4 > 0) {
            x = x >> 4;
            result = result << 2;
        };
        if (x >> 2 > 0) {
            result = result << 1;
        };

        result = (result + a / result) >> 1;
        result = (result + a / result) >> 1;
        result = (result + a / result) >> 1;
        result = (result + a / result) >> 1;
        result = (result + a / result) >> 1;
        result = (result + a / result) >> 1;
        result = (result + a / result) >> 1;
        min(result, a / result)
    }
//========================================================== TESTS ============================================================//
    // x^y
    #[test]
    fun pow_test() {
        assert!(pow(3,0) == 1, 1);
        assert!(pow(6,1) == 6, 1);
        assert!(pow(8,5) == 32768, 1);
    }
    // sqrt(x)
    #[test]
    fun sqrt_test() {
        assert!(sqrt(0) == 0, 1);
        assert!(sqrt(1) == 1, 1);
        assert!(sqrt(625) == 25, 1); // sqrt(25^2)
        assert!(sqrt(627) == 25, 1); // sqrt(25^2 + 2)
        assert!(sqrt(670) == 25, 1); // sqrt(26^2 - 6)
    }
}