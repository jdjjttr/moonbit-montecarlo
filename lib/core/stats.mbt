///|
/// Online running statistics collector for Monte Carlo path payoffs and risk metrics.
/// Employs Welford's algorithm to ensure high numerical precision for higher moments.

///|
/// Struct holding running statistics counters and accumulators.
pub struct StatsAccumulator {
  mut count : Int64
  mut mean : Double
  mut m2 : Double
  mut m3 : Double
  mut m4 : Double
  mut min_val : Double
  mut max_val : Double
}

///|
/// Create a fresh StatsAccumulator.
pub fn StatsAccumulator::new() -> StatsAccumulator {
  {
    count: 0L,
    mean: 0.0,
    m2: 0.0,
    m3: 0.0,
    m4: 0.0,
    min_val: 1.0e300,
    max_val: -1.0e300,
  }
}

///|
/// Push a single observation into the online statistics accumulator.
pub fn StatsAccumulator::push(self : StatsAccumulator, x : Double) -> Unit {
  let n1 = self.count
  self.count = self.count + 1L
  let n = self.count.to_double()

  if x < self.min_val {
    self.min_val = x
  }
  if x > self.max_val {
    self.max_val = x
  }

  let delta = x - self.mean
  let delta_n = delta / n
  let delta_n2 = delta_n * delta_n
  let term1 = delta * delta_n * n1.to_double()

  self.mean = self.mean + delta_n
  self.m4 = self.m4 +
    term1 * delta_n2 * (n * n - 3.0 * n + 3.0) +
    6.0 * delta_n2 * self.m2 -
    4.0 * delta_n * self.m3
  self.m3 = self.m3 + term1 * delta_n * (n - 2.0) - 3.0 * delta_n * self.m2
  self.m2 = self.m2 + term1
}

///|
/// Combine another StatsAccumulator into self.
pub fn StatsAccumulator::combine(
  self : StatsAccumulator,
  other : StatsAccumulator,
) -> Unit {
  if other.count == 0L {
    return
  }
  if self.count == 0L {
    self.count = other.count
    self.mean = other.mean
    self.m2 = other.m2
    self.m3 = other.m3
    self.m4 = other.m4
    self.min_val = other.min_val
    self.max_val = other.max_val
    return
  }

  let n1 = self.count.to_double()
  let n2 = other.count.to_double()
  let n = n1 + n2
  let delta = other.mean - self.mean
  let delta2 = delta * delta
  let delta3 = delta2 * delta
  let delta4 = delta3 * delta

  self.mean = self.mean + delta * n2 / n
  self.m4 = self.m4 +
    other.m4 +
    delta4 * n1 * n2 * (n1 * n1 - n1 * n2 + n2 * n2) / (n * n * n) +
    6.0 * delta2 * (n1 * n1 * other.m2 + n2 * n2 * self.m2) / (n * n) +
    4.0 * delta * (n1 * other.m3 - n2 * self.m3) / n
  self.m3 = self.m3 +
    other.m3 +
    delta3 * n1 * n2 * (n1 - n2) / (n * n) +
    3.0 * delta * (n1 * other.m2 - n2 * self.m2) / n
  self.m2 = self.m2 + other.m2 + delta2 * n1 * n2 / n
  self.count = self.count + other.count

  if other.min_val < self.min_val {
    self.min_val = other.min_val
  }
  if other.max_val > self.max_val {
    self.max_val = other.max_val
  }
}

///|
/// Get sample count.
pub fn StatsAccumulator::count(self : StatsAccumulator) -> Int64 {
  self.count
}

///|
/// Get sample mean.
pub fn StatsAccumulator::mean(self : StatsAccumulator) -> Double {
  if self.count == 0L {
    0.0
  } else {
    self.mean
  }
}

///|
/// Get sample variance (unbiased with N-1 denominator).
pub fn StatsAccumulator::variance(self : StatsAccumulator) -> Double {
  if self.count <= 1L {
    0.0
  } else {
    self.m2 / (self.count - 1L).to_double()
  }
}

///|
/// Get standard deviation.
pub fn StatsAccumulator::stddev(self : StatsAccumulator) -> Double {
  self.variance().sqrt()
}

///|
/// Get standard error of the mean (SE = stddev / sqrt(N)).
pub fn StatsAccumulator::standard_error(self : StatsAccumulator) -> Double {
  if self.count == 0L {
    0.0
  } else {
    self.stddev() / self.count.to_double().sqrt()
  }
}

///|
/// Get sample skewness.
pub fn StatsAccumulator::skewness(self : StatsAccumulator) -> Double {
  if self.count < 3L || self.m2 <= 0.0 {
    0.0
  } else {
    let n = self.count.to_double()
    n.sqrt() * self.m3 / (self.m2 * self.m2.sqrt())
  }
}

///|
/// Get excess kurtosis.
pub fn StatsAccumulator::kurtosis(self : StatsAccumulator) -> Double {
  if self.count < 4L || self.m2 <= 0.0 {
    0.0
  } else {
    let n = self.count.to_double()
    n * self.m4 / (self.m2 * self.m2) - 3.0
  }
}

///|
/// Minimum recorded observation.
pub fn StatsAccumulator::min(self : StatsAccumulator) -> Double {
  self.min_val
}

///|
/// Maximum recorded observation.
pub fn StatsAccumulator::max(self : StatsAccumulator) -> Double {
  self.max_val
}

///|
/// Compute symmetric confidence interval for the mean.
pub fn StatsAccumulator::confidence_interval(
  self : StatsAccumulator,
  level : Double,
) -> (Double, Double) {
  let alpha = (1.0 - level) / 2.0
  let z = norm_inv(1.0 - alpha)
  let se = self.standard_error()
  (self.mean - z * se, self.mean + z * se)
}

///|
/// Helper function to compute percentile of a given dataset array.
pub fn percentile(data : Array[Double], p : Double) -> Double {
  let len = data.length()
  if len == 0 {
    return 0.0
  }
  let sorted = data.copy()
  sorted.sort()
  let clamped_p = if p < 0.0 { 0.0 } else if p > 1.0 { 1.0 } else { p }
  let index_float = clamped_p * (len - 1).to_double()
  let idx = index_float.to_int()
  let frac = index_float - idx.to_double()
  if idx >= len - 1 {
    sorted[len - 1]
  } else {
    sorted[idx] * (1.0 - frac) + sorted[idx + 1] * frac
  }
}
