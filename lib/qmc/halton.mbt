///|
/// Halton Low-Discrepancy Sequence Generator for Quasi-Monte Carlo Integration.

///|
/// First 32 prime numbers for Halton sequence bases.
let halton_primes : Array[Int] = [
  2, 3, 5, 7, 11, 13, 17, 19, 23, 29, 31, 37, 41, 43, 47, 53, 59, 61, 67, 71, 73,
  79, 83, 89, 97, 101, 103, 107, 109, 113, 127, 131,
]

///|
/// Radical inverse function phi_b(index) in base b.
pub fn radical_inverse(index : Int, base : Int) -> Double {
  let mut f = 1.0
  let mut r = 0.0
  let mut i = index
  let base_d = base.to_double()
  while i > 0 {
    f = f / base_d
    r = r + f * (i % base).to_double()
    i = i / base
  }
  r
}

///|
/// Halton Sequence generator supporting up to 32 dimensions.
pub struct HaltonSequence {
  dim : Int
  mut current_index : Int
  scramble : Array[Double]
}

///|
/// Create a new Halton sequence generator for `dim` dimensions.
pub fn HaltonSequence::new(dim : Int, scramble_seed : UInt64) -> HaltonSequence {
  let clamped_dim = if dim < 1 { 1 } else if dim > 32 { 32 } else { dim }
  let scramble = Array::make(clamped_dim, 0.0)
  if scramble_seed != 0UL {
    let rng = @core.Xorshift128Plus::new(scramble_seed)
    let mut i = 0
    while i < clamped_dim {
      scramble[i] = rng.next_double()
      i = i + 1
    }
  }
  { dim: clamped_dim, current_index: 1, scramble }
}

///|
/// Advance generator and return the next D-dimensional uniform point in [0, 1)^D.
pub fn HaltonSequence::next_point(self : HaltonSequence) -> Array[Double] {
  let point = Array::make(self.dim, 0.0)
  let idx = self.current_index
  self.current_index = self.current_index + 1
  let mut d = 0
  while d < self.dim {
    let base = halton_primes[d]
    let mut val = radical_inverse(idx, base) + self.scramble[d]
    if val >= 1.0 {
      val = val - 1.0
    }
    point[d] = val
    d = d + 1
  }
  point
}

///|
/// Return next D-dimensional normal point mapped via inverse CDF N(0, 1)^D.
pub fn HaltonSequence::next_normal_point(
  self : HaltonSequence,
) -> Array[Double] {
  let u = self.next_point()
  let n = Array::make(self.dim, 0.0)
  let mut d = 0
  while d < self.dim {
    // Clamp uniform to avoid norm_inv infinity
    let clamped_u = if u[d] < 1.0e-12 {
      1.0e-12
    } else if u[d] > 1.0 - 1.0e-12 {
      1.0 - 1.0e-12
    } else {
      u[d]
    }
    n[d] = @core.norm_inv(clamped_u)
    d = d + 1
  }
  n
}
