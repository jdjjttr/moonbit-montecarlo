///|
/// Multi-Asset Rainbow Options Pricing Engine (Max-of-Two, Min-of-Two, Spread Options).

///|
/// Rainbow Option Type Enum.
pub(all) enum RainbowType {
  MaxOfTwo
  MinOfTwo
  Spread
}

///|
/// Price Rainbow Option using Multi-Asset Correlated GBM paths.
pub fn price_rainbow_option_mc(
  rainbow_type : RainbowType,
  ma_gbm : @multi_asset.MultiAssetGBM,
  strike : Double,
  r : Double,
  times : Array[Double],
  num_paths : Int,
  rng : @core.RngEngine,
) -> OptionPriceResult {
  let stats = @core.StatsAccumulator::new()
  let num_steps = times.length()
  let time_to_maturity = if num_steps > 0 { times[num_steps - 1] } else { 0.0 }
  let df = @math.exp(-r * time_to_maturity)

  let mut p = 0
  while p < num_paths {
    let paths = ma_gbm.generate_paths(times, rng)
    let s1_t = paths[0].terminal_value()
    let s2_t = if paths.length() > 1 { paths[1].terminal_value() } else { s1_t }

    let payoff = match rainbow_type {
      MaxOfTwo => {
        let m = if s1_t > s2_t { s1_t } else { s2_t }
        if m > strike {
          m - strike
        } else {
          0.0
        }
      }
      MinOfTwo => {
        let m = if s1_t < s2_t { s1_t } else { s2_t }
        if m > strike {
          m - strike
        } else {
          0.0
        }
      }
      Spread => {
        let diff = s1_t - s2_t
        if diff > strike {
          diff - strike
        } else {
          0.0
        }
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
