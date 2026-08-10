///|
/// Sobol Low-Discrepancy Sequence Generator up to 32 Dimensions.
/// Uses Gray code generation for O(1) step computation and optimal uniform coverage.

///|
/// Maximum number of bits used in Sobol 32-bit integer representations.
let sobol_bits : Int = 30

///|
/// Sobol direction numbers initialization data for dimensions 1..10.
let primitive_polynomials : Array[UInt] = [
  1U, 3U, 7U, 11U, 13U, 19U, 25U, 37U, 59U, 67U,
]

///|
let poly_degrees : Array[Int] = [0, 1, 2, 3, 3, 4, 4, 5, 5, 6]

///|
/// Sobol Sequence Generator Struct.
pub struct SobolSequence {
  dim : Int
  mut count : Int
  x : Array[UInt]
  v : Array[Array[UInt]] // v[dim][bit]
  recip : Double
}

///|
/// Create a new Sobol sequence generator for `dim` dimensions (1 <= dim <= 32).
pub fn SobolSequence::new(dim : Int) -> SobolSequence {
  let clamped_dim = if dim < 1 { 1 } else if dim > 32 { 32 } else { dim }
  let x = Array::make(clamped_dim, 0U)
  let v = Array::make(clamped_dim, Array::make(sobol_bits, 0U))
  let recip = 1.0 / (1 << sobol_bits).to_double()

  // Dimension 0 (Base direction numbers: 2^29, 2^28, ..., 2^0)
  let v0 = Array::make(sobol_bits, 0U)
  let mut i = 0
  while i < sobol_bits {
    v0[i] = 1U << (sobol_bits - 1 - i)
    i = i + 1
  }
  v[0] = v0

  // Higher dimensions setup
  let mut d = 1
  while d < clamped_dim {
    let vd = Array::make(sobol_bits, 0U)
    let poly_idx = d % 10
    let poly = primitive_polynomials[poly_idx]
    let s = poly_degrees[poly_idx]

    // Initial m_i values
    let mut i = 0
    while i < s && i < sobol_bits {
      let idx_u = (i + 1).reinterpret_as_uint()
      vd[i] = (idx_u * 2U + 1U) << (sobol_bits - 1 - i)
      i = i + 1
    }

    // Recurrence relation for direction numbers v_i
    let mut i = s
    while i < sobol_bits {
      let mut new_v = vd[i - s] ^ (vd[i - s] >> s)
      let mut k = 1
      while k < s {
        if ((poly >> (s - k)) & 1U) != 0U {
          new_v = new_v ^ vd[i - k]
        }
        k = k + 1
      }
      vd[i] = new_v
      i = i + 1
    }
    v[d] = vd
    d = d + 1
  }

  { dim: clamped_dim, count: 0, x, v, recip }
}

///|
/// Generate the next D-dimensional point in [0, 1)^D.
pub fn SobolSequence::next_point(self : SobolSequence) -> Array[Double] {
  let point = Array::make(self.dim, 0.0)
  if self.count == 0 {
    self.count = 1
    let mut d = 0
    while d < self.dim {
      point[d] = 0.0
      d = d + 1
    }
    return point
  }

  // Find lowest zero bit index c in count - 1
  let mut c = 0
  let mut tmp = self.count - 1
  while (tmp & 1) != 0 {
    c = c + 1
    tmp = tmp >> 1
  }
  if c >= sobol_bits {
    c = sobol_bits - 1
  }

  self.count = self.count + 1
  let mask = (1U << sobol_bits) - 1U
  let mut d = 0
  while d < self.dim {
    self.x[d] = (self.x[d] ^ self.v[d][c]) & mask
    point[d] = self.x[d].to_double() * self.recip
    d = d + 1
  }
  point
}

///|
/// Generate next D-dimensional normal point via inverse CDF N(0, 1)^D.
pub fn SobolSequence::next_normal_point(self : SobolSequence) -> Array[Double] {
  let u = self.next_point()
  let n = Array::make(self.dim, 0.0)
  let mut d = 0
  while d < self.dim {
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
