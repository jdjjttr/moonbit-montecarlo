///|
/// CLI Main Entrypoint.

///|
/// CLI main function.
fn main {
  let config = SimConfig::default()
  let report = run_simulation_batch(config)
  println(report)
}
