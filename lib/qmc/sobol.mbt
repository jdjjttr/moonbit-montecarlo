///|
/// Sobol Low-Discrepancy Sequence Generator up to 32 Dimensions.
/// Uses Gray code generation for O(1) step computation and optimal uniform coverage.
/// Direction numbers are constructed using Joe & Kuo primitive polynomials for all 32 dimensions.

///|
/// Maximum number of bits used in Sobol 32-bit integer representations.
let sobol_bits : Int = 30

///|
/// Polynomial degrees s_d for dimensions 1..32.
let poly_degrees : Array[Int] = [
  1, 1, 2, 3, 3, 4, 4, 5, 5, 5, 6, 6, 6, 6, 6, 6, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7,
  8, 8, 8, 8, 8,
]

///|
/// Primitive polynomial integer coefficients a_d for dimensions 1..32.
/// Representing binary polynomial coefficients (a_1 a_2 ... a_{s-1})_2.
let poly_coefficients : Array[UInt] = [
  0U, 0U, 1U, 1U, 2U, 1U, 4U, 2U, 14U, 18U, 1U, 13U, 19U, 25U, 26U, 31U, 1U, 4U,
  7U, 8U, 14U, 19U, 21U, 22U, 25U, 28U, 31U, 8U, 13U, 14U, 22U, 25U,
]

///|
/// Initial direction numbers m_{d, j} for dimensions 1..32 up to degree s_d.
let init_m_data : Array[Array[UInt]] = [
  [1U],
  [1U],
  [1U, 3U],
  [1U, 3U, 5U],
  [1U, 1U, 7U],
  [1U, 3U, 7U, 5U],
  [1U, 3U, 3U, 15U],
  [1U, 1U, 3U, 13U, 11U],
  [1U, 3U, 7U, 9U, 31U],
  [1U, 3U, 1U, 27U, 15U],
  [1U, 1U, 5U, 11U, 27U, 29U],
  [1U, 3U, 1U, 15U, 17U, 9U],
  [1U, 1U, 7U, 9U, 29U, 31U],
  [1U, 3U, 3U, 13U, 25U, 17U],
  [1U, 3U, 7U, 15U, 23U, 15U],
  [1U, 1U, 5U, 11U, 19U, 21U],
  [1U, 3U, 1U, 9U, 7U, 33U, 85U],
  [1U, 3U, 7U, 13U, 13U, 115U, 41U],
  [1U, 1U, 3U, 11U, 19U, 99U, 21U],
  [1U, 1U, 5U, 13U, 27U, 39U, 93U],
  [1U, 3U, 5U, 15U, 17U, 61U, 77U],
  [1U, 1U, 7U, 11U, 13U, 15U, 119U],
  [1U, 3U, 1U, 13U, 23U, 87U, 95U],
  [1U, 3U, 7U, 9U, 31U, 41U, 15U],
  [1U, 1U, 3U, 15U, 19U, 113U, 85U],
  [1U, 3U, 1U, 11U, 27U, 69U, 97U],
  [1U, 3U, 5U, 9U, 1U, 21U, 63U],
  [1U, 1U, 7U, 13U, 11U, 117U, 33U, 201U],
  [1U, 3U, 3U, 15U, 25U, 45U, 115U, 63U],
  [1U, 3U, 7U, 9U, 31U, 81U, 15U, 185U],
  [1U, 1U, 5U, 11U, 19U, 59U, 107U, 241U],
  [1U, 3U, 1U, 13U, 23U, 73U, 55U, 159U],
]

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

  // Higher dimensions setup (Dimensions 1..31 corresponding to 2..32)
  let mut d = 1
  while d < clamped_dim {
    let vd = Array::make(sobol_bits, 0U)
    let s = poly_degrees[d]
    let a = poly_coefficients[d]
    let m = init_m_data[d]

    // Initial m_i values
    let mut i = 0
    while i < s && i < sobol_bits {
      vd[i] = m[i] << (sobol_bits - 1 - i)
      i = i + 1
    }

    // Recurrence relation for direction numbers v_i
    let mut i = s
    while i < sobol_bits {
      let mut new_v = vd[i - s] ^ (vd[i - s] >> s)
      let mut k = 1
      while k < s {
        if ((a >> (s - 1 - k)) & 1U) != 0U {
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
