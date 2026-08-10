///|
/// Vasicek Short-Rate Process Model.
/// dr_t = a * (b - r_t) * dt + sigma * dW_t

///|
/// Vasicek Process Struct holding model parameters.
pub struct VasicekProcess {
  r0 : Double
  a : Double // Mean reversion speed
  b : Double // Long-term mean rate
  sigma : Double // Rate volatility
}

///|
/// Create a new Vasicek interest rate process.
pub fn VasicekProcess::new(
  r0 : Double,
  a : Double,
  b : Double,
  sigma : Double,
) -> VasicekProcess {
  { r0, a, b, sigma }
}

///|
/// Exact step transition solver for Vasicek process.
pub fn VasicekProcess::step(
  self : VasicekProcess,
  current_r : Double,
  dt : Double,
  z : Double,
) -> Double {
  let exp_adt = @math.exp(-self.a * dt)
  let mean = current_r * exp_adt + self.b * (1.0 - exp_adt)
  let var_factor = (1.0 - @math.exp(-2.0 * self.a * dt)) / (2.0 * self.a)
  let stddev = self.sigma * var_factor.sqrt()
  mean + stddev * z
}

///|
/// Generate a short-rate trajectory path over given time grid.
pub fn VasicekProcess::generate_path(
  self : VasicekProcess,
  times : Array[Double],
  rng : @core.RngEngine,
) -> @core.SimPath {
  let num_steps = times.length()
  let values = Array::make(num_steps, 0.0)
  if num_steps == 0 {
    return @core.SimPath::new(times, values)
  }
  values[0] = self.r0
  let mut i = 1
  while i < num_steps {
    let dt = times[i] - times[i - 1]
    let (z, _) = @core.sample_box_muller(rng)
    values[i] = self.step(values[i - 1], dt, z)
    i = i + 1
  }
  @core.SimPath::new(times, values)
}

///|
/// Analytical Zero-Coupon Bond Price P(0, T) under Vasicek Model.
pub fn VasicekProcess::zero_coupon_bond_price(
  self : VasicekProcess,
  maturity : Double,
) -> Double {
  let b_factor = (1.0 - @math.exp(-self.a * maturity)) / self.a
  let a_factor = @math.exp(
    (self.b - self.sigma * self.sigma / (2.0 * self.a * self.a)) *
    (b_factor - maturity) -
    self.sigma * self.sigma * b_factor * b_factor / (4.0 * self.a),
  )
  a_factor * @math.exp(-b_factor * self.r0)
}
