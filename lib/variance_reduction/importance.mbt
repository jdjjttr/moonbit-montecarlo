///|
/// Importance Sampling Variance Reduction for Rare Event Pricing.
/// Shift mean by mu_shift, re-weight payoffs using Radon-Nikodym derivative Likelihood Ratio.

///|
/// Importance sample output holding shifted sample value and likelihood weight ratio.
pub struct ShiftedSample {
  val : Double
  likelihood_ratio : Double
}

///|
/// Sample standard normal with mean shift, returning shifted variable and Radon-Nikodym weight.
pub fn sample_importance_normal(
  mean_shift : Double,
  rng : @core.RngEngine,
) -> ShiftedSample {
  let (z, _) = @core.sample_box_muller(rng)
  let shifted_z = z + mean_shift
  // Likelihood ratio L(x) = exp(-shift * x + 0.5 * shift^2)
  let weight = @math.exp(
    -mean_shift * shifted_z + 0.5 * mean_shift * mean_shift,
  )
  { val: shifted_z, likelihood_ratio: weight }
}
