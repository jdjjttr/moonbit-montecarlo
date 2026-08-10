///|
/// SABR (Stochastic Alpha Beta Rho) Volatility Model and Hagan Implied Volatility Formula.
/// dF_t = sigma_t * F_t^beta * dW_1,t
/// dsigma_t = alpha * sigma_t * dW_2,t
/// E[dW_1 dW_2] = rho dt

///|
/// SABR Model Struct.
pub struct SABRProcess {
  f0 : Double // Initial forward rate/price
  sigma0 : Double // Initial volatility alpha
  beta : Double // Elasticity parameter (0 <= beta <= 1)
  alpha : Double // Volatility of volatility (nu)
  rho : Double // Correlation (-1 <= rho <= 1)
}

///|
/// Create a new SABR Process.
pub fn SABRProcess::new(
  f0 : Double,
  sigma0 : Double,
  beta : Double,
  alpha : Double,
  rho : Double,
) -> SABRProcess {
  { f0, sigma0, beta, alpha, rho }
}

///|
/// Hagan's Analytical Implied Black Volatility Expansion Formula for SABR Model.
pub fn SABRProcess::hagan_implied_volatility(
  self : SABRProcess,
  strike : Double,
  time_to_maturity : Double,
) -> Double {
  if time_to_maturity <= 0.0 {
    return self.sigma0
  }
  let f = self.f0
  let k = strike
  let beta = self.beta
  let nu = self.alpha
  let rho = self.rho

  if (f - k).abs() <= 1.0e-6 {
    // ATM Implied Volatility
    let f_beta = @math.pow(f, 1.0 - beta)
    let term1 = self.sigma0 / f_beta
    let term2 = 1.0 +
      (
        (1.0 - beta) *
        (1.0 - beta) *
        self.sigma0 *
        self.sigma0 /
        (24.0 * f_beta * f_beta) +
        0.25 * rho * beta * nu * self.sigma0 / f_beta +
        (2.0 - 3.0 * rho * rho) / 24.0 * nu * nu
      ) *
      time_to_maturity
    return term1 * term2
  }

  let fk = f * k
  let log_fk = @math.ln(f / k)
  let fk_beta = @math.pow(fk, (1.0 - beta) / 2.0)

  let z = nu / self.sigma0 * fk_beta * log_fk
  let x_z = @math.ln(
    ((1.0 - 2.0 * rho * z + z * z).sqrt() + z - rho) / (1.0 - rho),
  )

  let z_over_xz = if x_z.abs() <= 1.0e-15 { 1.0 } else { z / x_z }

  let term1 = self.sigma0 /
    (
      fk_beta *
      (
        1.0 +
        (1.0 - beta) * (1.0 - beta) / 24.0 * log_fk * log_fk +
        (1.0 - beta) *
        (1.0 - beta) *
        (1.0 - beta) *
        (1.0 - beta) /
        1920.0 *
        log_fk *
        log_fk *
        log_fk *
        log_fk
      )
    )
  let term2 = z_over_xz
  let term3 = 1.0 +
    (
      (1.0 - beta) *
      (1.0 - beta) /
      24.0 *
      self.sigma0 *
      self.sigma0 /
      (fk_beta * fk_beta) +
      0.25 * rho * beta * nu * self.sigma0 / fk_beta +
      (2.0 - 3.0 * rho * rho) / 24.0 * nu * nu
    ) *
    time_to_maturity

  term1 * term2 * term3
}
