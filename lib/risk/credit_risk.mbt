///|
/// Structural Credit Risk and Credit Valuation Adjustment (CVA) Engine.
/// Based on Merton Model for Firm Asset Value V_t and Debt Barrier D.

///|
/// Merton Model Result Struct.
pub struct MertonCreditResult {
  distance_to_default : Double
  default_probability : Double
  credit_spread_bps : Double
}

///|
/// Compute Merton Structural Distance to Default (DD) and Default Probability (PD).
pub fn compute_merton_default_probability(
  asset_value : Double,
  debt_face_value : Double,
  asset_mu : Double,
  asset_sigma : Double,
  maturity : Double,
  risk_free_rate : Double,
) -> MertonCreditResult {
  if maturity <= 0.0 || asset_sigma <= 0.0 {
    return {
      distance_to_default: 0.0,
      default_probability: 0.0,
      credit_spread_bps: 0.0,
    }
  }

  let sqrt_t = maturity.sqrt()
  let drift = if asset_mu != 0.0 { asset_mu } else { risk_free_rate }
  let d2 = (
      @math.ln(asset_value / debt_face_value) +
      (drift - 0.5 * asset_sigma * asset_sigma) * maturity
    ) /
    (asset_sigma * sqrt_t)

  let dd = d2
  let pd = @core.norm_cdf(-dd)

  let expected_loss = debt_face_value * pd
  let spread = if asset_value <= 0.0 || expected_loss <= 0.0 {
    0.0
  } else {
    -@math.ln(expected_loss / asset_value) / maturity * 10000.0
  }
  let pos_spread = if spread < 0.0 { 0.0 } else { spread }

  {
    distance_to_default: dd,
    default_probability: pd,
    credit_spread_bps: pos_spread,
  }
}
