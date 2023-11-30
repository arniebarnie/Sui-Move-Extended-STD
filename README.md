
# Sui Move Extended Standard Library

Extended standard library for the Sui Move language
* [`u64`](#module-0x0u64)
* [`u128`](#module-0x0u128)
* [`u256`](#module-0x0u256)
* [`0x0::i64`](#module-0x0i64)
* [`0x0::fp64`](#module-0x0fp64)
* [`0x0::account`](#module-0x0account)
* [`0x0::ibalance`](#module-0x0ibalance)
* [`0x0::position`](#module-0x0position)

## Module [`0x0::u64`](/stl/sources/u64.move "u64")
Utility methods for `u64`
<pre>Calculate max(x,1)
<code><b>public</b> <b>fun</b> norm(x: u64): u64</code></pre>
<pre>Calculate min(x,y)
<code><b>public</b> <b>fun</b> min(x: u64, y: u64): u64</code></pre>
<pre>Calculate max(x,y)
<code><b>public</b> <b>fun</b> max(x: u64, y: u64): u64</code></pre>
<pre>Calculate |x-y|
<code><b>public</b> <b>fun</b> diff(x: u64, y: u64): u64</code></pre>
<pre>Calculate x^y
<code><b>public</b> <b>fun</b> pow(x: u64, y: u8): u64</code></pre>
<pre>Calculate √x
<code><b>public</b> <b>fun</b> sqrt(x: u64): u64</code></pre>
## Module [`0x0::u128`](/stl/sources/u128.move "u128")
Utility methods for `u128`
<pre>Calculate max(x,1)
<code><b>public</b> <b>fun</b> norm(x: u128): u128</code></pre>
<pre>Calculate min(x,y)
<code><b>public</b> <b>fun</b> min(x: u128, y: u128): u128</code></pre>
<pre>Calculate max(x,y)
<code><b>public</b> <b>fun</b> max(x: u128, y: u128): u128</code></pre>
<pre>Calculate |x-y|
<code><b>public</b> <b>fun</b> diff(x: u128, y: u128): u128</code></pre>
<pre>Calculate x^y
<code><b>public</b> <b>fun</b> pow(x: u128, y: u8): u128</code></pre>
<pre>Calculate √x
<code><b>public</b> <b>fun</b> sqrt(x: u128): u128</code></pre>
## Module [`0x0::u256`](/stl/sources/u256.move "u256")
Utility methods for `u256`
<pre>Calculate max(x,1)
<code><b>public</b> <b>fun</b> norm(x: u256): u256</code></pre>
<pre>Calculate min(x,y)
<code><b>public</b> <b>fun</b> min(x: u256, y: u256): u256</code></pre>
<pre>Calculate max(x,y)
<code><b>public</b> <b>fun</b> max(x: u256, y: u256): u256</code></pre>
<pre>Calculate |x-y|
<code><b>public</b> <b>fun</b> diff(x: u256, y: u256): u256</code></pre>
<pre>Calculate x^y
<code><b>public</b> <b>fun</b> pow(x: u256, y: u8): u64</code></pre>
<pre>Calculate √x
<code><b>public</b> <b>fun</b> sqrt(x: u256): u256</code></pre>
## Module [`0x0::i64`](/stl/sources/i64.move "i64")
Signed 64-bit integer
<pre><code><b>struct</b> I64 <b>has</b> <b>copy</b>, drop { bits: u64 }</code></pre>
<pre>Create I64 of value 0
<code><b>public</b> <b>fun</b> zero(): I64</code></pre>
<pre>Convert x to I64
<code><b>public</b> <b>fun</b> i64(x: u64): I64</code></pre>
<pre>Split x into sign and value
<code><b>public</b> <b>fun</b> u63(x: I64): u64</code></pre>
<pre>Split x into sign and absolute value
<code><b>public</b> <b>fun</b> split(x: I64): (bool, u64)</code></pre>
<pre>Get raw bits of x
<code><b>public</b> <b>fun</b> bits(x: I64): u64</code></pre>
<pre>Calculate max(0,x)
<code><b>public</b> <b>fun</b> plus(x: I64): u64</code></pre>
<pre>Calculate max(0,-x)
<code><b>public</b> <b>fun</b> minus(x: I64): u64</code></pre>
<pre>Return true if x > 0 else false
<code><b>public</b> <b>fun</b> sign(x: I64): bool</code></pre>
<pre>Calculate -|x|
<code><b>public</b> <b>fun</b> force(x: I64): I64</code></pre>
<pre>Calculate |x|
<code><b>public</b> <b>fun</b> abs(x: I64): I64</code></pre>
<pre>Check x == y
<code><b>public</b> <b>fun</b> eq(x: I64, y: I64): bool</code></pre>
<pre>Check x < y
<code><b>public</b> <b>fun</b> lt(x: I64, y: I64): bool</code></pre>
<pre>Check x <= y
<code><b>public</b> <b>fun</b> lte(x: I64, y: I64): bool</code></pre>
<pre>Check x > y
<code><b>public</b> <b>fun</b> gt(x: I64, y: I64): bool</code></pre>
<pre>Check x >= y
<code><b>public</b> <b>fun</b> gte(x: I64, y: I64): bool</code></pre>
<pre>Calculate min(x,y)
<code><b>public</b> <b>fun</b> min(x: I64, y: I64): I64</code></pre>
<pre>Calculate max(x,y)
<code><b>public</b> <b>fun</b> max(x: I64, y: I64): I64</code></pre>
<pre>Calculate x + y
<code><b>public</b> <b>fun</b> add(x: I64, y: I64): I64</code></pre>
<pre>Calculate x - y
<code><b>public</b> <b>fun</b> sub(x: I64, y: I64): I64</code></pre>
<pre>Calculate x * y
<code><b>public</b> <b>fun</b> mul(x: I64, y: I64): I64</code></pre>
<pre>Calculate x / y
<code><b>public</b> <b>fun</b> div(x: I64, y: I64): I64</code></pre>
<pre>Calculate |x - y|
<code><b>public</b> <b>fun</b> diff(x: I64, y: I64): I64</code></pre>
<pre>Calculate x^y
<code><b>public</b> <b>fun</b> pow(x: I64, y: u8): I64</code></pre>
## Module [`0x0::fp64`](/stl/sources/fp64.move "fp64")
64.64-bit fixed-point integer
<pre><code><b>struct</b> FP64 <b>has</b> <b>copy</b>, drop { bits: u128 }</code></pre>
<pre>Create FP64 of value 0
<code><b>public</b> <b>fun</b> zero(): FP64</code></pre>
<pre>Create FP64 from raw bits
<code><b>public</b> <b>fun</b> fp64(x: u128): FP64</code></pre>
<pre>Convert x to FP64
<code><b>public</b> <b>fun</b> int(x: u64): FP64</code></pre>
<pre>Calculate x / y as FP64
<code><b>public</b> <b>fun</b> frac(x: u64, y: u64): FP64</code></pre>
<pre>Convert 0x1::fixed_point32::FixedPoint32 to FP64
<code><b>public</b> <b>fun</b> fp32(x: FixedPoint32): FP64</code></pre>
<pre>Get raw bits of x
<code><b>public</b> <b>fun</b> bits(x: FP64): u128</code></pre>
<pre>Get center 32.32 bits of x
<code><b>public</b> <b>fun</b> center(x: FP64): u64</code></pre>
<pre>Check x == y
<code><b>public</b> <b>fun</b> eq(x: FP64, y: FP64): bool</code></pre>
<pre>Check x < y
<code><b>public</b> <b>fun</b> lt(x: FP64, y: FP64): bool</code></pre>
<pre>Check x <= y
<code><b>public</b> <b>fun</b> lte(x: FP64, y: FP64): bool</code></pre>
<pre>Check x > y
<code><b>public</b> <b>fun</b> gt(x: FP64, y: FP64): bool</code></pre>
<pre>Check x >= y
<code><b>public</b> <b>fun</b> gte(x: FP64, y: FP64): bool</code></pre>
<pre>Calculate min(x,y)
<code><b>public</b> <b>fun</b> min(x: FP64, y: FP64): FP64</code></pre>
<pre>Calculate max(x,y)
<code><b>public</b> <b>fun</b> max(x: FP64, y: FP64): FP64</code></pre>
<pre>Calculate x + y
<code><b>public</b> <b>fun</b> add(x: FP64, y: FP64): FP64</code></pre>
<pre>Calculate x - y
<code><b>public</b> <b>fun</b> sub(x: FP64, y: FP64): FP64</code></pre>
<pre>Calculate x * y
<code><b>public</b> <b>fun</b> mul(x: FP64, y: FP64): FP64</code></pre>
<pre>Calculate x / y
<code><b>public</b> <b>fun</b> div(x: FP64, y: FP64): FP64</code></pre>
<pre>Calculate |x - y|
<code><b>public</b> <b>fun</b> diff(x: FP64, y: FP64): FP64</code></pre>
<pre>Calculate x * y
<code><b>public</b> <b>fun</b> prod(x: u64, y: FP64): u64</code></pre>
<pre>Calculate x / y
<code><b>public</b> <b>fun</b> quot(x: u64, y: FP64): u64</code></pre>
## Module [`0x0::account`](/stl/sources/account.move "Account")
Permissionless address capability system
<pre><code><b>struct</b> Account <b>has</b> key, store  {
	id: <b>UID</b>,
	account_id: <b>address</b>
}</code></pre>
<pre>Create new account and capability
<code><b>public</b> <b>fun</b> new(ctx: &<b>mut</b> TxContext): u64</code></pre>
<pre>Duplicate account capability
<code><b>public</b> <b>fun</b> duplicate(account: & Account, ctx: &<b>mut</b> TxContext): u64</code></pre>
<pre>Get account ID
<code><b>public</b> <b>fun</b> id(account: & Account): <b>address</b></code></pre>
<pre>Destroy account capability
<code><b>public</b> <b>fun</b> destroy(account: Account)</code></pre>
## Module [`0x0::ibalance`](/stl/sources/ibalance.move "IBalance")
Balance holding signed 64-bit integer value
## Module [`0x0::position`](/stl/sources/position.move "Position") 
Collateralized position system# Sui Move Extended Standard Library
