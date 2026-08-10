///|
/// CLI Configuration Options Parser for Monte Carlo Simulations.

///|
/// Simulation Configuration Options Struct.
pub(all) struct SimConfig {
  asset_price : Double
  strike_price : Double
  risk_free_rate : Double
  volatility : Double
  maturity : Double
  num_paths : Int
  num_steps : Int
  seed : UInt64
  use_qmc : Bool
  output_format : String
}

///|
/// Create default simulation configuration.
pub fn SimConfig::default() -> SimConfig {
  {
    asset_price: 100.0,
    strike_price: 100.0,
    risk_free_rate: 0.05,
    volatility: 0.20,
    maturity: 1.0,
    num_paths: 1000,
    num_steps: 10,
    seed: 42UL,
    use_qmc: false,
    output_format: "markdown",
  }
}
