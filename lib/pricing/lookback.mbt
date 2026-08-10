///|
/// Lookback Option Pricing Engine (Floating Strike & Fixed Strike).

///|
/// Lookback Type Enum.
pub(all) enum LookbackType {
  FloatingStrike
  FixedStrike
}

///|
/// Monte Carlo Lookback Option Pricing Engine.
pub fn price_lookback_option_mc(
  option_type : OptionType,
  lookback_type : LookbackType,
  gbm : @stochastic.GBMProcess,
  fixed_strike : Double,
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
    let s_t = path.terminal_value()
    let s_max = path.max_value()
    let s_min = path.min_value()

    let payoff = match lookback_type {
      FloatingStrike =>
        match option_type {
          Call => s_t - s_min
          Put => s_max - s_t
        }
      FixedStrike =>
        match option_type {
          Call => if s_max > fixed_strike { s_max - fixed_strike } else { 0.0 }
          Put => if fixed_strike > s_min { fixed_strike - s_min } else { 0.0 }
        }
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
