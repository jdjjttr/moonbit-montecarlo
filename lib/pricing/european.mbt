///|
/// European Option Pricing Engine with Black-Scholes Analytical Benchmarks & Greeks.

///|
/// Option Type Enum.
pub(all) enum OptionType {
  Call
  Put
}

///|
/// Result struct holding Monte Carlo derivative pricing estimates.
pub(all) struct OptionPriceResult {
  price : Double
  standard_error : Double
  ci_lower : Double
  ci_upper : Double
}

///|
/// Analytical Black-Scholes Formula for European Options.
pub fn black_scholes_price(
  option_type : OptionType,
  s0 : Double,
  strike : Double,
  r : Double,
  sigma : Double,
  time_to_maturity : Double,
) -> Double {
  if time_to_maturity <= 0.0 {
    return match option_type {
      Call => if s0 > strike { s0 - strike } else { 0.0 }
      Put => if strike > s0 { strike - s0 } else { 0.0 }
    }
  }
  let sqrt_t = time_to_maturity.sqrt()
  let d1 = (
      @math.ln(s0 / strike) + (r + 0.5 * sigma * sigma) * time_to_maturity
    ) /
    (sigma * sqrt_t)
  let d2 = d1 - sigma * sqrt_t
  let df = @math.exp(-r * time_to_maturity)

  match option_type {
    Call => s0 * @core.norm_cdf(d1) - strike * df * @core.norm_cdf(d2)
    Put => strike * df * @core.norm_cdf(-d2) - s0 * @core.norm_cdf(-d1)
  }
}

///|
/// Analytical Black-Scholes Delta Greek.
pub fn black_scholes_delta(
  option_type : OptionType,
  s0 : Double,
  strike : Double,
  r : Double,
  sigma : Double,
  time_to_maturity : Double,
) -> Double {
  let sqrt_t = time_to_maturity.sqrt()
  let d1 = (
      @math.ln(s0 / strike) + (r + 0.5 * sigma * sigma) * time_to_maturity
    ) /
    (sigma * sqrt_t)
  match option_type {
    Call => @core.norm_cdf(d1)
    Put => @core.norm_cdf(d1) - 1.0
  }
}

///|
/// Analytical Black-Scholes Gamma Greek.
pub fn black_scholes_gamma(
  s0 : Double,
  strike : Double,
  r : Double,
  sigma : Double,
  time_to_maturity : Double,
) -> Double {
  let sqrt_t = time_to_maturity.sqrt()
  let d1 = (
      @math.ln(s0 / strike) + (r + 0.5 * sigma * sigma) * time_to_maturity
    ) /
    (sigma * sqrt_t)
  @core.norm_pdf(d1) / (s0 * sigma * sqrt_t)
}

///|
/// Monte Carlo European Option Pricing Engine.
pub fn price_european_option_mc(
  option_type : OptionType,
  gbm : @stochastic.GBMProcess,
  strike : Double,
  r : Double,
  time_to_maturity : Double,
  num_paths : Int,
  rng : @core.RngEngine,
) -> OptionPriceResult {
  let stats = @core.StatsAccumulator::new()
  let times = [0.0, time_to_maturity]
  let df = @math.exp(-r * time_to_maturity)

  let mut p = 0
  while p < num_paths {
    let path = gbm.generate_path(times, rng)
    let s_t = path.terminal_value()
    let payoff = match option_type {
      Call => if s_t > strike { s_t - strike } else { 0.0 }
      Put => if strike > s_t { strike - s_t } else { 0.0 }
    }
    stats.push(payoff * df)
    p = p + 1
  }

  let (ci_l, ci_u) = stats.confidence_interval(0.95)
  {
    price: stats.mean(),
    standard_error: stats.standard_error(),
    ci_lower: ci_l,
    ci_upper: ci_u,
  }
}
