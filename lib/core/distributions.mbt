///|
/// Continuous and Discrete Statistical Distributions for Financial Stochastic Modeling.

///|
/// Mathematical constants used in statistical evaluations.
let inv_sqrt_2pi : Double = 0.39894228040143267794

///|
/// Standard normal cumulative distribution function (CDF) using Hart's algorithm / error function approximation.
pub fn norm_cdf(x : Double) -> Double {
  if x < -8.0 {
    return 0.0
  }
  if x > 8.0 {
    return 1.0
  }
  let abs_x = if x < 0.0 { -x } else { x }
  let k = 1.0 / (1.0 + 0.2316419 * abs_x)
  let poly = k *
    (
      0.319381530 +
      k *
      (-0.356563782 + k * (1.781477937 + k * (-1.821255978 + 1.330274429 * k)))
    )
  let approx = 1.0 - inv_sqrt_2pi * @math.exp(-0.5 * x * x) * poly
  if x < 0.0 {
    1.0 - approx
  } else {
    approx
  }
}

///|
/// Standard normal probability density function (PDF).
pub fn norm_pdf(x : Double) -> Double {
  inv_sqrt_2pi * @math.exp(-0.5 * x * x)
}

///|
/// Inverse cumulative distribution function (Quantile function) of Standard Normal Distribution N(0, 1)
/// using Peter Acklam's high-precision rational approximation algorithm.
pub fn norm_inv(p : Double) -> Double {
  if p <= 0.0 {
    return -999999.0
  }
  if p >= 1.0 {
    return 999999.0
  }

  let a1 = -3.969683028665376e+01
  let a2 = 2.209460984245205e+02
  let a3 = -2.759285104469687e+02
  let a4 = 1.383577518672690e+02
  let a5 = -3.066479806614716e+01
  let a6 = 2.506628277459239e+00

  let b1 = -5.447609879822406e+01
  let b2 = 1.615858368580409e+02
  let b3 = -1.556989798598866e+02
  let b4 = 6.680131188771972e+01
  let b5 = -1.328068155288572e+01

  let c1 = -7.784894002430293e-03
  let c2 = -3.223964580411365e-01
  let c3 = -2.400758277161838e+00
  let c4 = -2.549732539343734e+00
  let c5 = 4.374664141464968e+00
  let c6 = 2.938163982698783e+00

  let d1 = 7.784695709041462e-03
  let d2 = 3.224671290700398e-01
  let d3 = 2.445134137142996e+00
  let d4 = 3.754408661907416e+00

  let p_low = 0.02425
  let p_high = 1.0 - p_low

  if p < p_low {
    let q = (-2.0 * @math.ln(p)).sqrt()
    ((((c1 * q + c2) * q + c3) * q + c4) * q + c5) * q +
    c6 / ((((d1 * q + d2) * q + d3) * q + d4) * q + 1.0)
  } else if p <= p_high {
    let q = p - 0.5
    let r = q * q
    (((((a1 * r + a2) * r + a3) * r + a4) * r + a5) * r + a6) *
    q /
    (((((b1 * r + b2) * r + b3) * r + b4) * r + b5) * r + 1.0)
  } else {
    let q = (-2.0 * @math.ln(1.0 - p)).sqrt()
    -(((((c1 * q + c2) * q + c3) * q + c4) * q + c5) * q + c6) /
    ((((d1 * q + d2) * q + d3) * q + d4) * q + 1.0)
  }
}

///|
/// Uniform Distribution U(a, b).
pub struct UniformDist {
  a : Double
  b : Double
}

///|
/// Create a new Uniform Distribution.
pub fn UniformDist::new(a : Double, b : Double) -> UniformDist {
  { a, b }
}

///|
/// Sample a single value from Uniform Distribution.
pub fn UniformDist::sample(self : UniformDist, rng : RngEngine) -> Double {
  self.a + (self.b - self.a) * rng.next_double()
}

///|
/// PDF of Uniform Distribution.
pub fn UniformDist::pdf(self : UniformDist, x : Double) -> Double {
  if x >= self.a && x <= self.b {
    1.0 / (self.b - self.a)
  } else {
    0.0
  }
}

///|
/// CDF of Uniform Distribution.
pub fn UniformDist::cdf(self : UniformDist, x : Double) -> Double {
  if x < self.a {
    0.0
  } else if x > self.b {
    1.0
  } else {
    (x - self.a) / (self.b - self.a)
  }
}

///|
/// Normal Distribution N(mean, stddev^2).
pub struct NormalDist {
  mean : Double
  stddev : Double
}

///|
/// Create a new Normal Distribution.
pub fn NormalDist::new(mean : Double, stddev : Double) -> NormalDist {
  { mean, stddev }
}

///|
/// Standard Normal Distribution N(0, 1).
pub fn NormalDist::standard() -> NormalDist {
  { mean: 0.0, stddev: 1.0 }
}

///|
/// Sample a pair of independent standard normal random variables using Box-Muller transform.
pub fn sample_box_muller(rng : RngEngine) -> (Double, Double) {
  let mut u1 = rng.next_double()
  while u1 <= 1.0e-15 {
    u1 = rng.next_double()
  }
  let u2 = rng.next_double()
  let r = (-2.0 * @math.ln(u1)).sqrt()
  let theta = 2.0 * @math.PI * u2
  (r * @math.cos(theta), r * @math.sin(theta))
}

///|
/// Sample from Normal Distribution N(mean, stddev^2).
pub fn NormalDist::sample(self : NormalDist, rng : RngEngine) -> Double {
  let (z1, _) = sample_box_muller(rng)
  self.mean + self.stddev * z1
}

///|
/// PDF of Normal Distribution.
pub fn NormalDist::pdf(self : NormalDist, x : Double) -> Double {
  let z = (x - self.mean) / self.stddev
  norm_pdf(z) / self.stddev
}

///|
/// CDF of Normal Distribution.
pub fn NormalDist::cdf(self : NormalDist, x : Double) -> Double {
  let z = (x - self.mean) / self.stddev
  norm_cdf(z)
}

///|
/// Inverse CDF (Quantile) of Normal Distribution.
pub fn NormalDist::quantile(self : NormalDist, p : Double) -> Double {
  self.mean + self.stddev * norm_inv(p)
}

///|
/// Exponential Distribution Exp(lambda).
pub struct ExponentialDist {
  rate : Double
}

///|
/// Create a new Exponential Distribution.
pub fn ExponentialDist::new(rate : Double) -> ExponentialDist {
  { rate, }
}

///|
/// Sample from Exponential Distribution.
pub fn ExponentialDist::sample(
  self : ExponentialDist,
  rng : RngEngine,
) -> Double {
  let mut u = rng.next_double()
  while u <= 1.0e-15 {
    u = rng.next_double()
  }
  -@math.ln(u) / self.rate
}

///|
/// PDF of Exponential Distribution.
pub fn ExponentialDist::pdf(self : ExponentialDist, x : Double) -> Double {
  if x < 0.0 {
    0.0
  } else {
    self.rate * @math.exp(-self.rate * x)
  }
}

///|
/// CDF of Exponential Distribution.
pub fn ExponentialDist::cdf(self : ExponentialDist, x : Double) -> Double {
  if x < 0.0 {
    0.0
  } else {
    1.0 - @math.exp(-self.rate * x)
  }
}

///|
/// Poisson Distribution Poisson(lambda).
pub struct PoissonDist {
  lambda : Double
}

///|
/// Create a new Poisson Distribution.
pub fn PoissonDist::new(lambda : Double) -> PoissonDist {
  { lambda, }
}

///|
/// Sample from Poisson Distribution using Knuth's algorithm.
pub fn PoissonDist::sample(self : PoissonDist, rng : RngEngine) -> Int {
  let l = @math.exp(-self.lambda)
  let mut k = 0
  let mut p = 1.0
  while p > l {
    k = k + 1
    p = p * rng.next_double()
  }
  k - 1
}

///|
/// Student-t Distribution StudentT(df).
pub struct StudentTDist {
  df : Double
}

///|
/// Create a new Student-t Distribution.
pub fn StudentTDist::new(df : Double) -> StudentTDist {
  { df, }
}

///|
/// Sample from Student-t Distribution using Normal and Chi-Square ratio.
pub fn StudentTDist::sample(self : StudentTDist, rng : RngEngine) -> Double {
  let (z, _) = sample_box_muller(rng)
  let mut chi_sq = 0.0
  let degrees = self.df.to_int()
  let n = if degrees < 1 { 1 } else { degrees }
  let mut i = 0
  while i < n {
    let (x, _) = sample_box_muller(rng)
    chi_sq = chi_sq + x * x
    i = i + 1
  }
  z / (chi_sq / self.df).sqrt()
}
