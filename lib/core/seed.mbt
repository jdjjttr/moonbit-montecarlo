///|
/// High-performance, bit-exact deterministic pseudo-random number generator suite
/// designed for financial Monte Carlo simulations.

///|
/// Xorshift128Plus PRNG state holding two 64-bit unsigned integers.
pub struct Xorshift128Plus {
  mut s0 : UInt64
  mut s1 : UInt64
}

///|
/// Create a new Xorshift128Plus generator initialized from a 64-bit seed.
pub fn Xorshift128Plus::new(seed : UInt64) -> Xorshift128Plus {
  let mut s = if seed == 0UL { 0xdeadbeef12345678UL } else { seed }
  s = s ^ (s >> 30)
  s = s * 0xbf58476d1ce4e5b9UL
  s = s ^ (s >> 27)
  s = s * 0x94d049bb133111ebUL
  let st0 = s ^ (s >> 31)

  s = st0 + 0x9e3779b97f4a7c15UL
  s = s ^ (s >> 30)
  s = s * 0xbf58476d1ce4e5b9UL
  s = s ^ (s >> 27)
  s = s * 0x94d049bb133111ebUL
  let st1 = s ^ (s >> 31)

  { s0: st0, s1: st1 }
}

///|
/// Generate the next pseudo-random 64-bit unsigned integer using Xorshift128+.
pub fn Xorshift128Plus::next_u64(self : Xorshift128Plus) -> UInt64 {
  let mut x = self.s0
  let y = self.s1
  self.s0 = y
  x = x ^ (x << 23)
  self.s1 = x ^ y ^ (x >> 17) ^ (y >> 26)
  self.s1 + y
}

///|
/// Generate a pseudo-random double precision floating point number in [0.0, 1.0).
pub fn Xorshift128Plus::next_double(self : Xorshift128Plus) -> Double {
  let raw = self.next_u64()
  let mantissa = (raw >> 11).to_double()
  mantissa * (1.0 / 9007199254740992.0)
}

///|
/// PCG32 (Permuted Congruential Generator - 32-bit output, 64-bit state).
pub struct PCG32 {
  mut state : UInt64
  inc : UInt64
}

///|
/// Create a new PCG32 generator given an initial state seed and sequence selector.
pub fn PCG32::new(seed : UInt64, seq : UInt64) -> PCG32 {
  let inc = (seq << 1) | 1UL
  let pcg = { state: 0UL, inc }
  pcg.next_u32() |> ignore
  pcg.state = pcg.state + seed
  pcg.next_u32() |> ignore
  pcg
}

///|
/// Generate the next pseudo-random 32-bit unsigned integer using PCG32 XSH-RR algorithm.
pub fn PCG32::next_u32(self : PCG32) -> UInt {
  let oldstate = self.state
  self.state = oldstate * 6364136223846793005UL + self.inc
  let xorshifted = (((oldstate >> 18) ^ oldstate) >> 27).to_uint()
  let rot = (oldstate >> 59).to_int()
  (xorshifted >> rot) | (xorshifted << ((0 - rot) & 31))
}

///|
/// Generate a pseudo-random double precision float in [0.0, 1.0) using PCG32.
pub fn PCG32::next_double(self : PCG32) -> Double {
  let u1 = self.next_u32().to_double()
  let u2 = self.next_u32().to_double()
  (u1 * 4294967296.0 + u2) * (1.0 / 18446744073709551616.0)
}

///|
/// SplitMix64 generator - useful for seeding other generators and fast random numbers.
pub struct SplitMix64 {
  mut state : UInt64
}

///|
/// Create a new SplitMix64 generator with a 64-bit seed.
pub fn SplitMix64::new(seed : UInt64) -> SplitMix64 {
  { state: seed }
}

///|
/// Generate next 64-bit unsigned int with SplitMix64.
pub fn SplitMix64::next_u64(self : SplitMix64) -> UInt64 {
  self.state = self.state + 0x9e3779b97f4a7c15UL
  let mut z = self.state
  z = (z ^ (z >> 30)) * 0xbf58476d1ce4e5b9UL
  z = (z ^ (z >> 27)) * 0x94d049bb133111ebUL
  z ^ (z >> 31)
}

///|
/// Generate next double in [0.0, 1.0) with SplitMix64.
pub fn SplitMix64::next_double(self : SplitMix64) -> Double {
  let val = self.next_u64() >> 11
  val.to_double() * (1.0 / 9007199254740992.0)
}

///|
/// Uniform Random Number Generator Interface Enum.
pub enum RngEngine {
  Xorshift(Xorshift128Plus)
  Pcg(PCG32)
  SplitMix(SplitMix64)
}

///|
/// Create a default RngEngine with Xorshift128+.
pub fn RngEngine::default(seed : UInt64) -> RngEngine {
  RngEngine::Xorshift(Xorshift128Plus::new(seed))
}

///|
/// Create PCG32 engine wrapper.
pub fn RngEngine::pcg(seed : UInt64, seq : UInt64) -> RngEngine {
  RngEngine::Pcg(PCG32::new(seed, seq))
}

///|
/// Create SplitMix64 engine wrapper.
pub fn RngEngine::splitmix(seed : UInt64) -> RngEngine {
  RngEngine::SplitMix(SplitMix64::new(seed))
}

///|
/// Sample next double in [0.0, 1.0) from the unified RngEngine.
pub fn RngEngine::next_double(self : RngEngine) -> Double {
  match self {
    Xorshift(rng) => rng.next_double()
    Pcg(rng) => rng.next_double()
    SplitMix(rng) => rng.next_double()
  }
}
