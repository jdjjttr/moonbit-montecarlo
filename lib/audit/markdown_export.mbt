///|
/// Executive Summary Markdown Report Generator.

///|
/// Generate Executive Markdown Summary Report.
pub fn generate_executive_report(
  title : String,
  audit : AuditTrail,
  opt_res : @pricing.OptionPriceResult,
  var_res : @risk.VaRResult,
) -> String {
  let sb = StringBuilder::new()
  sb.write_string(
    "# 📊 Monte Carlo Simulation Audit Report: " + title + "\n\n",
  )
  sb.write_string("## ⚙️ Reproducibility Audit Metadata\n\n")
  sb.write_string("| Parameter | Audit Value |\n")
  sb.write_string("| :--- | :--- |\n")
  sb.write_string("| **Random Seed** | `" + audit.seed.to_string() + "` |\n")
  sb.write_string(
    "| **Simulated Paths** | `" + audit.num_paths.to_string() + "` |\n",
  )
  sb.write_string(
    "| **Time Grid Steps** | `" + audit.num_steps.to_string() + "` |\n",
  )
  sb.write_string(
    "| **Path FNV Checksum** | `" + audit.path_checksum.to_string() + "` |\n\n",
  )

  sb.write_string("## 💰 Derivative Pricing Engine Results\n\n")
  sb.write_string(
    "- **Estimated Fair Value**: `" + opt_res.price.to_string() + "`\n",
  )
  sb.write_string(
    "- **Standard Error**: `" + opt_res.standard_error.to_string() + "`\n",
  )
  sb.write_string(
    "- **95% Confidence Interval**: `[" +
    opt_res.ci_lower.to_string() +
    ", " +
    opt_res.ci_upper.to_string() +
    "]`\n\n",
  )

  sb.write_string("## 📉 Value at Risk (VaR) Analysis\n\n")
  sb.write_string("- **Method**: `" + var_res.method_name + "`\n")
  sb.write_string(
    "- **Confidence Level**: `" +
    (var_res.confidence_level * 100.0).to_string() +
    "%`\n",
  )
  sb.write_string(
    "- **Value at Risk (VaR)**: `" + var_res.var_value.to_string() + "`\n",
  )
  sb.to_string()
}
