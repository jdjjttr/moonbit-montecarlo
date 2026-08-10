///|
/// JSON Serialization Exporter for Simulation Results and Risk Metrics.

///|
/// Export OptionPriceResult into a JSON string.
pub fn export_option_result_json(
  result : @pricing.OptionPriceResult,
  label : String,
) -> String {
  let sb = StringBuilder::new()
  sb.write_string("{\n")
  sb.write_string("  \"label\": \"" + label + "\",\n")
  sb.write_string("  \"price\": " + result.price.to_string() + ",\n")
  sb.write_string(
    "  \"standard_error\": " + result.standard_error.to_string() + ",\n",
  )
  sb.write_string("  \"ci_lower\": " + result.ci_lower.to_string() + ",\n")
  sb.write_string("  \"ci_upper\": " + result.ci_upper.to_string() + "\n")
  sb.write_string("}")
  sb.to_string()
}

///|
/// Export VaRResult into a JSON string.
pub fn export_var_result_json(result : @risk.VaRResult) -> String {
  let sb = StringBuilder::new()
  sb.write_string("{\n")
  sb.write_string(
    "  \"confidence_level\": " + result.confidence_level.to_string() + ",\n",
  )
  sb.write_string("  \"var_value\": " + result.var_value.to_string() + ",\n")
  sb.write_string("  \"method_name\": \"" + result.method_name + "\"\n")
  sb.write_string("}")
  sb.to_string()
}
