///|
/// Cliquet (Ratchet) Option Pricing Engine.
/// Accumulates periodic returns clamped by local cap and local floor.

///|
/// Cliquet Option Result Struct.
pub struct CliquetResult {
  price : Double
  standard_error : Double
  average_return : Double
}

///|
/// Monte Carlo Cliquet Option Pricing Engine.
pub fn price_cliquet_option_mc(
  gbm : @stochastic.GBMProcess,
  r : Double,
  times : Array[Double],
  local_cap : Double,
  local_floor : Double,
  global_cap : Double,
  global_floor : Double,
  num_paths : Int,
  rng : @core.RngEngine,
) -> CliquetResult {
  let stats = @core.StatsAccumulator::new()
  let return_stats = @core.StatsAccumulator::new()
  let num_steps = times.length()
  let time_to_maturity = if num_steps > 0 { times[num_steps - 1] } else { 0.0 }
  let df = @math.exp(-r * time_to_maturity)

  let mut p = 0
  while p < num_paths {
    let path = gbm.generate_path(times, rng)
    let mut total_cliquet_return = 0.0

    let mut i = 1
    while i < num_steps {
      let s_prev = path.get(i - 1)
      let s_curr = path.get(i)
      let raw_ret = if s_prev <= 1.0e-15 {
        0.0
      } else {
        (s_curr - s_prev) / s_prev
      }

      // Clamp return between local floor and local cap
      let capped_ret = if raw_ret > local_cap { local_cap } else { raw_ret }
      let floored_ret = if capped_ret < local_floor {
        local_floor
      } else {
        capped_ret
      }

      total_cliquet_return = total_cliquet_return + floored_ret
      i = i + 1
    }

    // Apply global cap and global floor
    let g_capped = if total_cliquet_return > global_cap {
      global_cap
    } else {
      total_cliquet_return
    }
    let final_ret = if g_capped < global_floor {
      global_floor
    } else {
      g_capped
    }

    let payoff = if final_ret > 0.0 { final_ret } else { 0.0 }
    stats.push(payoff * df)
    return_stats.push(final_ret)
    p = p + 1
  }

  {
    price: stats.mean(),
    standard_error: stats.standard_error(),
    average_return: return_stats.mean(),
  }
}
