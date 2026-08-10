///|
/// Financial Stress Testing and Macro Shock Scenario Engine.

///|
/// Stress Scenario Specification.
pub struct StressScenario {
  scenario_name : String
  drift_shock : Double
  volatility_multiplier : Double
}

///|
/// Create a new Stress Scenario.
pub fn StressScenario::new(
  name : String,
  drift_shock : Double,
  vol_mult : Double,
) -> StressScenario {
  { scenario_name: name, drift_shock, volatility_multiplier: vol_mult }
}

///|
/// Stress Test Result output struct for a single scenario.
pub struct StressTestResult {
  scenario_name : String
  base_mean_price : Double
  stressed_mean_price : Double
  price_change_pct : Double
}

///|
/// Helper to construct a stressed GBM process instance.
pub fn create_stressed_gbm(
  s0 : Double,
  mu : Double,
  sigma : Double,
) -> @stochastic.GBMProcess {
  @stochastic.create_gbm(s0, mu, sigma)
}

///|
/// Run a suite of financial stress scenarios against a baseline GBM asset process.
pub fn run_stress_test_suite(
  base_gbm : @stochastic.GBMProcess,
  scenarios : Array[StressScenario],
  times : Array[Double],
  num_paths : Int,
  rng : @core.RngEngine,
) -> Array[StressTestResult] {
  let base_path_matrix = base_gbm.generate_matrix(num_paths, times, rng)
  let base_stats = @core.StatsAccumulator::new()
  let mut p = 0
  while p < num_paths {
    base_stats.push(base_path_matrix.get(p, times.length() - 1))
    p = p + 1
  }
  let base_mean = base_stats.mean()

  let results = Array::make(scenarios.length(), {
    scenario_name: "",
    base_mean_price: 0.0,
    stressed_mean_price: 0.0,
    price_change_pct: 0.0,
  })
  let mut s = 0
  while s < scenarios.length() {
    let sc = scenarios[s]
    let s0 = base_path_matrix.get(0, 0)
    let stressed_mu = base_gbm.generate_path([0.0], rng).initial_value() * 0.0 +
      sc.drift_shock
    let stressed_sigma = sc.volatility_multiplier * 0.2
    let stressed_gbm = create_stressed_gbm(s0, stressed_mu, stressed_sigma)

    let str_matrix = stressed_gbm.generate_matrix(num_paths, times, rng)
    let str_stats = @core.StatsAccumulator::new()
    let mut p = 0
    while p < num_paths {
      str_stats.push(str_matrix.get(p, times.length() - 1))
      p = p + 1
    }
    let str_mean = str_stats.mean()
    let pct = if base_mean != 0.0 {
      (str_mean - base_mean) / base_mean * 100.0
    } else {
      0.0
    }

    results[s] = {
      scenario_name: sc.scenario_name,
      base_mean_price: base_mean,
      stressed_mean_price: str_mean,
      price_change_pct: pct,
    }
    s = s + 1
  }
  results
}
