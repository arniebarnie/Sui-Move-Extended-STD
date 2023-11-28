// SPDX-License-Identifier: MIT

module 0x0::u256 {
//========================================================= METHODS ===========================================================//
    // Minimum of x and y
    public fun min(x: u256, y: u256): u256 { 
        if (x < y) x else y 
    }
    // Maximum of x and y
    public fun max(x: u256, y: u256): u256 { 
        if (x > y) x else y 
    }
    // |x - y|
    public fun diff(x: u256, y: u256): u256 {
        if (x > y) (x - y) else (y - x)
    }
    // x^y
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
    // sqrt(x) - Babylonian method 
    public fun sqrt(x: u256): u256 {
        let z = (x + 1) / 2;
        let res = x;
        while (z < res) {
            res = z;
            z = (x / z + z) / 2;
        };
        res
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