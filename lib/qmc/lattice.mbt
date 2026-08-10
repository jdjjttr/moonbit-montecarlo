///|
/// Korobov Rank-1 Lattice Rule Quasi-Monte Carlo Generator.
/// Provides optimal multi-dimensional integration rules with optional random shift.

///|
/// Korobov Rank-1 Lattice Struct.
pub struct LatticeSequence {
  num_points : Int
  dim : Int
  generator : Int
  shift : Array[Double]
}

///|
/// Create a new Korobov Rank-1 Lattice Rule generator.
pub fn LatticeSequence::new(
  num_points : Int,
  dim : Int,
  generator : Int,
  shift_seed : UInt64,
) -> LatticeSequence {
  let shift = Array::make(dim, 0.0)
  if shift_seed != 0UL {
    let rng = @core.Xorshift128Plus::new(shift_seed)
    let mut d = 0
    while d < dim {
      shift[d] = rng.next_double()
      d = d + 1
    }
  }
  { num_points, dim, generator, shift }
}

///|
/// Get the k-th lattice point (0 <= k < num_points) in [0, 1)^D.
pub fn LatticeSequence::point(self : LatticeSequence, k : Int) -> Array[Double] {
  let res = Array::make(self.dim, 0.0)
  let n = self.num_points.to_double()
  let mut g_pow = 1L
  let g = self.generator.to_int64()
  let n_i = self.num_points.to_int64()

  let mut d = 0
  while d < self.dim {
    let raw_k = k.to_int64() * g_pow % n_i
    let mut u = raw_k.to_double() / n + self.shift[d]
    if u >= 1.0 {
      u = u - 1.0
    }
    res[d] = u
    g_pow = g_pow * g % n_i
    d = d + 1
  }
  res
}

///|
/// Get the k-th lattice point mapped to standard normal N(0, 1)^D.
pub fn LatticeSequence::normal_point(
  self : LatticeSequence,
  k : Int,
) -> Array[Double] {
  let u = self.point(k)
  let res = Array::make(self.dim, 0.0)
  let mut d = 0
  while d < self.dim {
    let clamped_u = if u[d] < 1.0e-12 {
      1.0e-12
    } else if u[d] > 1.0 - 1.0e-12 {
      1.0 - 1.0e-12
    } else {
      u[d]
    }
    res[d] = @core.norm_inv(clamped_u)
    d = d + 1
  }
  res
}
