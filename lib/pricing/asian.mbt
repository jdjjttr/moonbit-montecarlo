///|
/// Asian Option Pricing Engine (Arithmetic & Geometric Average Options).

///|
/// Averaging Method Enum.
pub(all) enum AveragingMethod {
  Arithmetic
  Geometric
}

///|
/// Monte Carlo Asian Option Pricing Engine.
pub fn price_asian_option_mc(
  option_type : OptionType,
  avg_method : AveragingMethod,
  gbm : @stochastic.GBMProcess,
  strike : Double,
  r : Double,
  times : Array[Double],
  num_paths : Int,
  rng : @core.RngEngine,
) -> OptionPriceResult {
  let stats = @core.StatsAccumulator::new()
  let time_to_maturity = if times.length() > 0 {
    times[times.length() - 1]
  } else {
    0.0
  }
  let df = @math.exp(-r * time_to_maturity)

  let mut p = 0
  while p < num_paths {
    let path = gbm.generate_path(times, rng)
    let avg_price = match avg_method {
      Arithmetic => path.arithmetic_mean()
      Geometric => path.geometric_mean()
    }
    let payoff = match option_type {
      Call => if avg_price > strike { avg_price - strike } else { 0.0 }
      Put => if strike > avg_price { strike - avg_price } else { 0.0 }
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
