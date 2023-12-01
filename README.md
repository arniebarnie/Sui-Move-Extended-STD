

# Sui Move Extended Standard Library

Extended standard library for the Sui Move language
* [`0x0::account`](#module-0x0account)
* [`0x0::box`](#module-0x0box)
* [`0x0::ibalance`](#module-0x0ibalance)
* [`0x0::position`](#module-0x0position)
* [`0x0::fp64`](#module-0x0fp64)
* [`0x0::i64`](#module-0x0i64)
* [`0x0::u64`](#module-0x0u64)
* [`0x0::u128`](#module-0x0u128)
* [`0x0::u256`](#module-0x0u256)

## Module [`0x0::account`](/stl/sources/account.move "Account")
Permissionless address capability system
<pre><code><b>struct</b> Account <b>has</b> key, store  {
	id: <b>UID</b>,
	account_id: <b>address</b>
}</code></pre>
<pre>
<code><b>public</b> <b>fun</b> new(ctx: &<b>mut</b> TxContext): Account // Create new account and capability</code></pre>
<pre>
<code><b>public</b> <b>fun</b> duplicate(account: & Account, ctx: &<b>mut</b> TxContext): Account // Duplicate account capability</code></pre>
<pre>
<code><b>public</b> <b>fun</b> id(account: & Account): <b>address</b> // Get account ID</code></pre>
<pre>
<code><b>public</b> <b>fun</b> destroy(account: Account) // Destroy account capability</code></pre>
## Module [`0x0::box`](/stl/sources/box.move "Box")
Generic box to place objects without keys in global storage
<pre><code><b>struct</b> Box&ltT: store&gt <b>has</b> key, store  {
	id: <b>UID</b>,
	item: T
}</code></pre>
<pre>
<code><b>public</b> <b>fun</b> box&ltT&gt(item: T, ctx: &<b>mut</b> TxContext): Box&ltT&gt // Box item</code></pre>
<pre>
<code><b>public</b> <b>fun</b> unbox&ltT&gt(item: T): T // Unbox item</code></pre>
<pre>
<code><b>public</b> <b>fun</b> borrow&ltT&gt(box: Box&ltT&gt): & T // Borrow item</code></pre>
<pre>
<code><b>public</b> <b>fun</b> borrow_mut&ltT&gt(box: Box&ltT&gt): &<b>mut</b> T // Mutably borrow item</code></pre>
## Module [`0x0::ibalance`](/stl/sources/ibalance.move "IBalance")
Balance holding signed 64-bit integer value
<pre><code><b>struct</b> IBalance&lt<b>phantom</b> T&gt <b>has</b> store { value: I64 }</code></pre>
<pre><code><b>public</b> <b>fun</b> mint&ltT&gt(_: &<b>mut</b> Supply&ltT&gt, value: I64): IBalance&ltT&gt // Create a balance with a value</code></pre>
<pre><code><b>public</b> <b>fun</b> zero&ltT&gt(): IBalance&ltT&gt // Create a balance of value 0</code></pre>
<pre><code><b>public</b> <b>fun</b> value&ltT&gt(self: &<b>mut</b> IBalance&ltT&gt): u64 // Get value of balance</code></pre>
<pre><code><b>public</b> <b>fun</b> join&ltT&gt(self: &<b>mut</b> IBalance&ltT&gt, balance: IBalance&ltT&gt) // Join value of balance to another balance</code></pre>
<pre><code><b>public</b> <b>fun</b> merge&ltT&gt(self: IBalance&ltT&gt, balance: IBalance&ltT&gt): IBalance&ltT&gt // Merge two balances</code></pre>
<pre><code><b>public</b> <b>fun</b> split&ltT&gt(self: IBalance&ltT&gt, value: I64): IBalance&ltT&gt // Split balance from balance</code></pre>
<pre><code><b>public</b> <b>fun</b> destroy&ltT&gt(balance: IBalance&ltT&gt): IBalance&ltT&gt // Destroy balance - aborts if value is not 0</code></pre>
<pre><code><b>public</b> <b>fun</b> burn&ltT&gt(_: &<b>mut</b> Supply&ltT&gt, balance: IBalance&ltT&gt) // Burn balance</code></pre>
## Module [`0x0::position`](/stl/sources/position.move "Position") 
Non custodial collateralized position system
<pre><code><b>public</b> <b>fun</b> get&ltT&gt(registry: & PoolRegistry): (address, vector&ltu8&gt) // Get (address, metadata) for pool of given type</code></pre>
<pre><code>// Create new position pool
// Must own type of positions
<b>public</b> <b>fun</b> new&ltT:drop,Q&gt(registry: & PoolRegistry, _: T, rate: FP64, closure: u64, metadata: vector&ltu8&gt): (address, vector&ltu8&gt)
</code></pre>
<pre><code><b>public</b> <b>fun</b> id&ltT,Q&gt(pool: & Pool&ltT,Q&gt): address // Get pool ID</code></pre>
<pre><code><b>public</b> <b>fun</b> rate&ltT,Q&gt(pool: & Pool&ltT,Q&gt): FP64 // Get pool collateralization rate</code></pre>
<pre><code><b>public</b> <b>fun</b> collateral&ltT,Q&gt(pool: & Pool&ltT,Q&gt): FP64 // Get pool collateral total</code></pre>
<pre><code><b>public</b> <b>fun</b> settled&ltT,Q&gt(pool: & Pool&ltT,Q&gt, clock: & Clock): bool // Check if pool is settled</code></pre>
<pre><code><b>public</b> <b>fun</b> winning&ltT,Q&gt(pool: & Pool&ltT,Q&gt): FP64 // Get pool winning rate</code></pre>
<pre><code><b>public</b> <b>fun</b> needed&ltT,Q&gt(pool: & Pool&ltT,Q&gt, quantity: u64): u64 // Calculate collateral needed for position creation</code></pre>
<pre><code>// Underwrite position with collateral
<b>public</b> <b>fun</b> underwrite&ltT,Q&gt(pool: &<b>mut</b> Pool&ltT,Q&gt, quantity: u64, collateral: &<b>mut</b> Balance&ltQ&gt, clock: & Clock): (Balance&ltPosition&ltT&gt&gt, Balance&ltNote&ltT&gt&gt)</code></pre>
<pre><code>// Close position with note to release collateral
<b>public</b> <b>fun</b> close&ltT,Q&gt(pool: &<b>mut</b> Pool&ltT,Q&gt, quantity: u64, position: Balance&ltPosition&ltT&gt&gt, note: Balance&ltNote&ltT&gt&gt, collateral: &<b>mut</b> Balance&ltQ&gt, clock: & Clock)</code></pre>
<pre><code><b>public</b> <b>fun</b> locked&ltT,Q&gt(pool: & Pool&ltT,Q&gt, note: & Balance&ltNote&ltT&gt&gt): u64 // Collateral locked under note</code></pre>
<pre><code>// Update position pool winnings rate
<b>public</b> <b>fun</b> update&ltT:drop,Q&gt(pool: &<b>mut</b> Pool&ltT,Q&gt, winning: FP64, clock: & Clock)</code></pre>
<pre><code>// Claim winnings for position from settled pool
<b>public</b> <b>fun</b> claim&ltT,Q&gt(pool: &<b>mut</b> Pool&ltT,Q&gt, position: Balance&ltPosition&ltT&gt&gt, clock: & Clock): Balance&ltQ&gt</code></pre>
<pre><code>// Unlock remaining collateral for note from settled pool
<b>public</b> <b>fun</b> unlock&ltT,Q&gt(pool: &<b>mut</b> Pool&ltT,Q&gt, note: Balance&ltNote&ltT&gt&gt, clock: & Clock): Balance&ltQ&gt </code></pre>
<pre><code>// Empty collateral pool after all positions and notes settled
<b>public</b> <b>fun</b> drain&ltT,Q&gt(pool: &<b>mut</b> Pool&ltT,Q&gt, _: T, clock: & Clock): Balance&ltQ&gt </code></pre>
## Module [`0x0::fp64`](/stl/sources/fp64.move "fp64")
64.64-bit fixed-point integer
<pre><code><b>struct</b> FP64 <b>has</b> <b>copy</b>, drop { bits: u128 }</code></pre>
<pre>
<code><b>public</b> <b>fun</b> zero(): FP64 // Create FP64 of value 0</code></pre>
<pre>
<code><b>public</b> <b>fun</b> fp64(x: u128): FP64 // Create FP64 from raw bits</code></pre>
<pre>
<code><b>public</b> <b>fun</b> int(x: u64): FP64 // Convert x to FP64</code></pre>
<pre>
<code><b>public</b> <b>fun</b> frac(x: u64, y: u64): FP64 // Calculate x / y as FP64</code></pre>
<pre>
<code><b>public</b> <b>fun</b> fp32(x: FixedPoint32): FP64 // Convert 0x1::fixed_point32::FixedPoint32 to FP64</code></pre>
<pre>
<code><b>public</b> <b>fun</b> bits(x: FP64): u128 // Get raw bits of x</code></pre>
<pre>
<code><b>public</b> <b>fun</b> center(x: FP64): u64 // Get center 32.32 bits of x</code></pre>
<pre>
<code><b>public</b> <b>fun</b> eq(x: FP64, y: FP64): bool // Check x == y</code></pre>
<pre>
<code><b>public</b> <b>fun</b> lt(x: FP64, y: FP64): bool // Check x < y</code></pre>
<pre>
<code><b>public</b> <b>fun</b> lte(x: FP64, y: FP64): bool // Check x <= y</code></pre>
<pre>
<code><b>public</b> <b>fun</b> gt(x: FP64, y: FP64): bool // Check x > y</code></pre>
<pre>
<code><b>public</b> <b>fun</b> gte(x: FP64, y: FP64): bool // Check x >= y</code></pre>
<pre>
<code><b>public</b> <b>fun</b> min(x: FP64, y: FP64): FP64 // Calculate min(x,y)</code></pre>
<pre>
<code><b>public</b> <b>fun</b> max(x: FP64, y: FP64): FP64 // Calculate max(x,y)</code></pre>
<pre>
<code><b>public</b> <b>fun</b> add(x: FP64, y: FP64): FP64 // Calculate x + y</code></pre>
<pre>
<code><b>public</b> <b>fun</b> sub(x: FP64, y: FP64): FP64 // Calculate x - y</code></pre>
<pre>
<code><b>public</b> <b>fun</b> mul(x: FP64, y: FP64): FP64 // Calculate x * y</code></pre>
<pre>
<code><b>public</b> <b>fun</b> div(x: FP64, y: FP64): FP64 // Calculate x / y</code></pre>
<pre>
<code><b>public</b> <b>fun</b> diff(x: FP64, y: FP64): FP64 // Calculate |x - y|</code></pre>
<pre>
<code><b>public</b> <b>fun</b> prod(x: u64, y: FP64): u64 // Calculate x * y</code></pre>
<pre>
<code><b>public</b> <b>fun</b> quot(x: u64, y: FP64): u64 // Calculate x / y</code></pre>
## Module [`0x0::i64`](/stl/sources/i64.move "i64")
Signed 64-bit integer
<pre><code><b>struct</b> I64 <b>has</b> <b>copy</b>, drop { bits: u64 }</code></pre>
<pre>
<code><b>public</b> <b>fun</b> zero(): I64 // Create I64 of value 0</code></pre>
<pre>
<code><b>public</b> <b>fun</b> i64(x: u64): I64 // Convert x to I64</code></pre>
<pre>
<code><b>public</b> <b>fun</b> u63(x: I64): u64 // Split x into sign and value</code></pre>
<pre>
<code><b>public</b> <b>fun</b> split(x: I64): (bool, u64) // Split x into sign and absolute value</code></pre>
<pre>
<code><b>public</b> <b>fun</b> bits(x: I64): u64 // Get raw bits of x</code></pre>
<pre>
<code><b>public</b> <b>fun</b> plus(x: I64): u64 // Calculate max(0,x)</code></pre>
<pre>
<code><b>public</b> <b>fun</b> minus(x: I64): u64 // Calculate max(0,-x)</code></pre>
<pre>
<code><b>public</b> <b>fun</b> sign(x: I64): bool // Return true if x > 0 else false</code></pre>
<pre>
<code><b>public</b> <b>fun</b> force(x: I64): I64 // Calculate -|x|</code></pre>
<pre>
<code><b>public</b> <b>fun</b> abs(x: I64): I64 // Calculate |x|</code></pre>
<pre>
<code><b>public</b> <b>fun</b> eq(x: I64, y: I64): bool // Check x == y</code></pre>
<pre>
<code><b>public</b> <b>fun</b> lt(x: I64, y: I64): bool // Check x < y</code></pre>
<pre>
<code><b>public</b> <b>fun</b> lte(x: I64, y: I64): bool // Check x <= y</code></pre>
<pre>
<code><b>public</b> <b>fun</b> gt(x: I64, y: I64): bool // Check x > y</code></pre>
<pre>
<code><b>public</b> <b>fun</b> gte(x: I64, y: I64): bool // Check x >= y</code></pre>
<pre>
<code><b>public</b> <b>fun</b> min(x: I64, y: I64): I64 // Calculate min(x,y)</code></pre>
<pre>
<code><b>public</b> <b>fun</b> max(x: I64, y: I64): I64 // Calculate max(x,y)</code></pre>
<pre>
<code><b>public</b> <b>fun</b> add(x: I64, y: I64): I64 // Calculate x + y</code></pre>
<pre>
<code><b>public</b> <b>fun</b> sub(x: I64, y: I64): I64 // Calculate x - y</code></pre>
<pre>
<code><b>public</b> <b>fun</b> mul(x: I64, y: I64): I64 // Calculate x * y</code></pre>
<pre>
<code><b>public</b> <b>fun</b> div(x: I64, y: I64): I64 // Calculate x / y</code></pre>
<pre>
<code><b>public</b> <b>fun</b> diff(x: I64, y: I64): I64 // Calculate |x - y|</code></pre>
<pre>
<code><b>public</b> <b>fun</b> pow(x: I64, y: u8): I64 // Calculate x^y</code></pre>
## Module [`0x0::u64`](/stl/sources/u64.move "u64")
Utility methods for `u64`
<pre>
<code><b>public</b> <b>fun</b> norm(x: u64): u64 // Calculate max(1,x)</code></pre>
<pre>
<code><b>public</b> <b>fun</b> min(x: u64, y: u64): u64 // Calculate min(x,y)</code></pre>
<pre>
<code><b>public</b> <b>fun</b> max(x: u64, y: u64): u64 // Calculate max(x,y)</code></pre>
<pre>
<code><b>public</b> <b>fun</b> diff(x: u64, y: u64): u64 // Calculate |x-y|</code></pre>
<pre>
<code><b>public</b> <b>fun</b> pow(x: u64, y: u8): u64 // Calculate x^y</code></pre>
<pre>
<code><b>public</b> <b>fun</b> sqrt(x: u64): u64 // Calculate √x</code></pre>
<pre>
<code><b>public</b> <b>fun</b> scaled(x: u64, y: u64, z: u64): u64 // Calculate (x*y)/z</code></pre>
## Module [`0x0::u128`](/stl/sources/u128.move "u128")
Utility methods for `u128`

<pre>
<code><b>public</b> <b>fun</b> norm(x: u128): u128 // Calculate max(1,x)</code></pre>
<pre>
<code><b>public</b> <b>fun</b> min(x: u128, y: u128): u128 // Calculate min(x,y)</code></pre>
<pre>
<code><b>public</b> <b>fun</b> max(x: u128, y: u128): u128 // Calculate max(x,y)</code></pre>
<pre>
<code><b>public</b> <b>fun</b> diff(x: u128, y: u128): u128 // Calculate |x-y|</code></pre>
<pre>
<code><b>public</b> <b>fun</b> pow(x: u128, y: u8): u128 // Calculate x^y</code></pre>
<pre>
<code><b>public</b> <b>fun</b> sqrt(x: u128): u128 // Calculate √x</code></pre>
<pre>
<code><b>public</b> <b>fun</b> scaled(x: u128, y: u128, z: u128): u128 // Calculate (x*y)/z</code></pre>
## Module [`0x0::u256`](/stl/sources/u256.move "u256")
Utility methods for `u256`

<pre>
<code><b>public</b> <b>fun</b> norm(x: u256): u256 // Calculate max(1,x)</code></pre>
<pre>
<code><b>public</b> <b>fun</b> min(x: u256, y: u256): u256 // Calculate min(x,y)</code></pre>
<pre>
<code><b>public</b> <b>fun</b> max(x: u256, y: u256): u256 // Calculate max(x,y)</code></pre>
<pre>
<code><b>public</b> <b>fun</b> diff(x: u256, y: u256): u256 // Calculate |x-y|</code></pre>
<pre>
<code><b>public</b> <b>fun</b> pow(x: u256, y: u8): u256 // Calculate x^y</code></pre>
<pre>
<code><b>public</b> <b>fun</b> sqrt(x: u256): u256 // Calculate √x</code></pre>
<pre>
