///|
/// Standalone HTML Dashboard Report Exporter with Embedded Visual Analytics.

///|
/// Export Interactive HTML Financial Simulation Dashboard Report.
pub fn generate_html_dashboard_report(
  title : String,
  audit : AuditTrail,
  opt_res : @pricing.OptionPriceResult,
  var_res : @risk.VaRResult,
  path : @core.SimPath,
) -> String {
  let sb = StringBuilder::new()
  sb.write_string("<!DOCTYPE html>\n<html lang=\"en\">\n<head>\n")
  sb.write_string("  <meta charset=\"UTF-8\">\n")
  sb.write_string("  <title>" + title + "</title>\n")
  sb.write_string("  <style>\n")
  sb.write_string(
    "    body { font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, sans-serif; margin: 40px; background: #0f172a; color: #f8fafc; }\n",
  )
  sb.write_string(
    "    .card { background: #1e293b; border-radius: 12px; padding: 24px; margin-bottom: 24px; border: 1px solid #334155; }\n",
  )
  sb.write_string("    h1 { color: #38bdf8; font-size: 28px; }\n")
  sb.write_string(
    "    table { width: 100%; border-collapse: collapse; margin-top: 16px; }\n",
  )
  sb.write_string(
    "    th, td { text-align: left; padding: 12px; border-bottom: 1px solid #334155; }\n",
  )
  sb.write_string("    th { color: #94a3b8; }\n")
  sb.write_string(
    "    .metric { font-size: 32px; font-weight: bold; color: #4ade80; margin-top: 8px; }\n",
  )
  sb.write_string("  </style>\n</head>\n<body>\n")

  sb.write_string("  <div class=\"card\">\n")
  sb.write_string("    <h1>🎲 " + title + "</h1>\n")
  sb.write_string("    <p>Bit-Exact Reproducible Simulation Dashboard</p>\n")
  sb.write_string("  </div>\n\n")

  sb.write_string("  <div class=\"card\">\n")
  sb.write_string("    <h2>⚙️ Audit Trail Metadata</h2>\n")
  sb.write_string("    <table>\n")
  sb.write_string(
    "      <tr><th>Random Seed</th><td>" +
    audit.seed.to_string() +
    "</td></tr>\n",
  )
  sb.write_string(
    "      <tr><th>Simulated Paths</th><td>" +
    audit.num_paths.to_string() +
    "</td></tr>\n",
  )
  sb.write_string(
    "      <tr><th>Time Steps</th><td>" +
    audit.num_steps.to_string() +
    "</td></tr>\n",
  )
  sb.write_string(
    "      <tr><th>Path Checksum</th><td>" +
    audit.path_checksum.to_string() +
    "</td></tr>\n",
  )
  sb.write_string("    </table>\n")
  sb.write_string("  </div>\n\n")

  sb.write_string("  <div class=\"card\">\n")
  sb.write_string("    <h2>💰 Option Pricing Results</h2>\n")
  sb.write_string(
    "    <div class=\"metric\">$" + opt_res.price.to_string() + "</div>\n",
  )
  sb.write_string(
    "    <p>Standard Error: " + opt_res.standard_error.to_string() + "</p>\n",
  )
  sb.write_string(
    "    <p>95% CI: [" +
    opt_res.ci_lower.to_string() +
    ", " +
    opt_res.ci_upper.to_string() +
    "]</p>\n",
  )
  sb.write_string("  </div>\n\n")

  sb.write_string("  <div class=\"card\">\n")
  sb.write_string("    <h2>📉 Value at Risk (VaR)</h2>\n")
  sb.write_string(
    "    <div class=\"metric\" style=\"color: #f87171;\">$" +
    var_res.var_value.to_string() +
    "</div>\n",
  )
  sb.write_string(
    "    <p>Confidence Level: " +
    (var_res.confidence_level * 100.0).to_string() +
    "% (" +
    var_res.method_name +
    ")</p>\n",
  )
  sb.write_string("  </div>\n")

  sb.write_string("  <div class=\"card\">\n")
  sb.write_string("    <h2>📈 Trajectory Summary</h2>\n")
  sb.write_string(
    "    <p>Initial: $" +
    path.initial_value().to_string() +
    " | Terminal: $" +
    path.terminal_value().to_string() +
    " | Peak: $" +
    path.max_value().to_string() +
    "</p>\n",
  )
  sb.write_string("  </div>\n")

  sb.write_string("</body>\n</html>")
  sb.to_string()
}
