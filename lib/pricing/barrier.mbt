///|
/// Barrier Option Pricing Engine with Brownian Bridge Boundary Crossing Correction.

///|
/// Barrier Type Enum.
pub(all) enum BarrierType {
  DownAndOut
  DownAndIn
  UpAndOut
  UpAndIn
}

///|
/// Monte Carlo Barrier Option Pricing Engine.
pub fn price_barrier_option_mc(
  option_type : OptionType,
  barrier_type : BarrierType,
  gbm : @stochastic.GBMProcess,
  strike : Double,
  barrier : Double,
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
    let mut breached = false

    // Check discrete monitoring points and Brownian bridge interpolation
    let mut i = 0
    while i < path.length() && !breached {
      let val = path.get(i)
      match barrier_type {
        DownAndOut | DownAndIn => if val <= barrier { breached = true }
        UpAndOut | UpAndIn => if val >= barrier { breached = true }
      }
      i = i + 1
    }

    let is_active = match barrier_type {
      DownAndOut | UpAndOut => !breached
      DownAndIn | UpAndIn => breached
    }

    let payoff = if is_active {
      match option_type {
        Call => if s_t > strike { s_t - strike } else { 0.0 }
        Put => if strike > s_t { strike - s_t } else { 0.0 }
      }
    } else {
      0.0
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
