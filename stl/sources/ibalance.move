// SPDX-License-Identifier: MIT

module 0x0::ibalance {
//======================================================== IMPORTS ============================================================//
    use 0x0::i64::{Self, I64};
	use 0x2::balance::Supply;
//======================================================= ERROR CODES =========================================================//
    const ENotEmpty: u64 = 3;
//========================================================= OBJECTS ===========================================================//
    // Balance capable of holding a positive or negative value
    struct IBalance<phantom T> has store { 
            value: I64 
    }
//========================================================= METHODS ===========================================================//
    // Create a balance with a value
	public fun mint<T>(_: &mut Supply<T>, value: I64): IBalance<T> {
			IBalance { value }
	}
	// Create a zero balance
    public fun zero<T>(): IBalance<T> {
            IBalance { value: i64::zero() }
    }
    // Get value of balance
    public fun value<T>(balance: & IBalance<T>): I64 {
            balance.value
    }
    // Join value of balance to another balance
    public fun join<T>(self: &mut IBalance<T>, balance: IBalance<T>) {
        let IBalance { value } = balance;
        self.value = i64::add(self.value, value);
    }
    // Merge two balances
    public fun merge<T>(self: IBalance<T>, balance: IBalance<T>): IBalance<T> {
        let IBalance { value } = balance;
        self.value = i64::add(self.value, value);
        self
    }
    // Split balance from balance
    public fun split<T>(self: &mut IBalance<T>, value: I64): IBalance<T> {
        self.value = i64::sub(self.value, value);
        IBalance { value }
    }
    // Destroy balance
    public fun destroy<T>(balance: IBalance<T>) {
        let IBalance { value } = balance;
		assert!(value == i64::zero(), ENotEmpty);
    }
	// Burn balance
	public fun burn<T>(_: &mut Supply<T>, balance: IBalance<T>) {
		let IBalance { value: _ } = balance;
	}
//========================================================== TESTS ============================================================//
	#[test_only]
	struct X has drop { }
	#[test]
	fun zero_test() {
		let balance = zero<X>();
		assert!(balance.value == i64::zero(), 1);
		let IBalance { value: _ } = balance;
	}
	#[test]
	fun value_test() {
		let balance = zero<X>();
		assert!(value(& balance) == i64::zero(), 1);
		let IBalance { value: _ } = balance;
		let balance = IBalance<X> { value: i64::i64(5) };
		assert!(value(& balance) == i64::i64(5), 1);
		let IBalance { value: _ } = balance;
		let balance = IBalance<X> { value: i64::neg(i64::i64(5)) };
		assert!(value(& balance) == i64::neg(i64::i64(5)), 1);
		let IBalance { value: _ } = balance;
	}
	#[test]
	fun join_test() {
		let balance = zero<X>();
		let balance_1 = IBalance<X> { value: i64::i64(5) };
		join(&mut balance, balance_1);
		assert!(balance.value == i64::i64(5), 1);
		let balance_2 = IBalance<X> { value: i64::neg(i64::i64(5)) };
		join(&mut balance, balance_2);
		assert!(balance.value == i64::zero(), 1);
		let IBalance { value: _ } = balance;
	}
	#[test]
	fun merge_test() {
		let balance_1 = IBalance<X> { value: i64::i64(5) };
		let balance_2 = IBalance<X> { value: i64::neg(i64::i64(5)) };
		let balance = merge(balance_1, balance_2);
		assert!(balance.value == i64::zero(), 1);
		let IBalance { value: _ } = balance;
	}
	#[test]
	fun split_test() {
		let balance = IBalance<X> { value: i64::i64(5) };
		let balance_1 = split(&mut balance, i64::i64(3));
		assert!(balance_1.value == i64::i64(3), 1);
		assert!(balance.value == i64::i64(2), 1);
		let IBalance { value: _ } = balance_1;
		let IBalance { value: _ } = balance;
	}
	#[test]
	fun destroy_test() {
		let balance = IBalance<X> { value: i64::zero() };
		destroy(balance);
	}
	#[test]
	#[expected_failure]
	fun destroy_test_fail() {
		let balance = IBalance<X> { value: i64::i64(5) };
		destroy(balance);
	}
}