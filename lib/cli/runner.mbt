///|
/// Batch Simulation Executor and Report Runner.

///|
/// Execute Monte Carlo simulation pipeline given a SimConfig specification.
pub fn run_simulation_batch(config : SimConfig) -> String {
  let gbm = @stochastic.create_gbm(
    config.asset_price,
    config.risk_free_rate,
    config.volatility,
  )
  let times = Array::make(config.num_steps + 1, 0.0)
  let dt = config.maturity / config.num_steps.to_double()
  let mut i = 0
  while i <= config.num_steps {
    times[i] = i.to_double() * dt
    i = i + 1
  }

  let rng = @core.RngEngine::default(config.seed)
  let matrix = gbm.generate_matrix(config.num_paths, times, rng)
  let audit = @audit.AuditTrail::new(
    config.seed,
    config.num_paths,
    config.num_steps + 1,
    matrix,
  )

  let rng_pricing = @core.RngEngine::default(config.seed)
  let opt_res = @pricing.price_european_option_mc(
    @pricing.Call,
    gbm,
    config.strike_price,
    config.risk_free_rate,
    config.maturity,
    config.num_paths,
    rng_pricing,
  )

  let var_res = @risk.compute_gbm_monte_carlo_var(
    0.95,
    gbm,
    times,
    config.num_paths,
    rng_pricing,
  )

  if config.output_format == "json" {
    let sb = StringBuilder::new()
    sb.write_string("{\n")
    sb.write_string("  \"audit\": " + audit.to_json() + ",\n")
    sb.write_string(
      "  \"option_pricing\": " +
      @audit.export_option_result_json(opt_res, "European Call") +
      ",\n",
    )
    sb.write_string(
      "  \"risk\": " + @audit.export_var_result_json(var_res) + "\n",
    )
    sb.write_string("}")
    sb.to_string()
  } else {
    @audit.generate_executive_report(
      "MoonBit Financial Monte Carlo Engine", audit, opt_res, var_res,
    )
  }
}
