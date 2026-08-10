///|
/// Finite Difference Monte Carlo Greeks Engine (Delta, Gamma, Vega, Theta, Rho).

///|
/// Struct holding calculated Greeks.
pub struct MonteCarloGreeks {
  delta : Double
  gamma : Double
  vega : Double
  theta : Double
  rho : Double
}

///|
/// Compute Monte Carlo Greeks using central finite difference approximations.
pub fn compute_mc_greeks(
  s0 : Double,
  mu : Double,
  sigma : Double,
  strike : Double,
  r : Double,
  time_to_maturity : Double,
  pricing_fn : (Double, Double, Double, Double, Double, Double) -> Double,
) -> MonteCarloGreeks {
  let eps_s = s0 * 0.01
  let price_plus_s = pricing_fn(
    s0 + eps_s,
    mu,
    sigma,
    strike,
    r,
    time_to_maturity,
  )
  let price_base = pricing_fn(s0, mu, sigma, strike, r, time_to_maturity)
  let price_minus_s = pricing_fn(
    s0 - eps_s,
    mu,
    sigma,
    strike,
    r,
    time_to_maturity,
  )

  let delta = (price_plus_s - price_minus_s) / (2.0 * eps_s)
  let gamma = (price_plus_s - 2.0 * price_base + price_minus_s) /
    (eps_s * eps_s)

  let eps_vol = 0.01
  let price_plus_vol = pricing_fn(
    s0,
    mu,
    sigma + eps_vol,
    strike,
    r,
    time_to_maturity,
  )
  let price_minus_vol = pricing_fn(
    s0,
    mu,
    sigma - eps_vol,
    strike,
    r,
    time_to_maturity,
  )
  let vega = (price_plus_vol - price_minus_vol) / (2.0 * eps_vol)

  let eps_t = 0.01
  let price_plus_t = pricing_fn(
    s0,
    mu,
    sigma,
    strike,
    r,
    time_to_maturity + eps_t,
  )
  let theta = -(price_plus_t - price_base) / eps_t

  let eps_r = 0.001
  let price_plus_r = pricing_fn(
    s0,
    mu,
    sigma,
    strike,
    r + eps_r,
    time_to_maturity,
  )
  let rho = (price_plus_r - price_base) / eps_r

  { delta, gamma, vega, theta, rho }
}
