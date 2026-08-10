///|
test "audit_trail_verification" {
  let pm1 = @core.PathMatrix::new(2, 2)
  pm1.set(0, 0, 100.0)
  pm1.set(0, 1, 105.0)

  let pm2 = @core.PathMatrix::new(2, 2)
  pm2.set(0, 0, 100.0)
  pm2.set(0, 1, 105.0)

  let trail1 = @audit.AuditTrail::new(42UL, 2, 2, pm1)
  let trail2 = @audit.AuditTrail::new(42UL, 2, 2, pm2)
  assert_true(@audit.AuditTrail::verify(trail1, trail2))
}

///|
test "csv_path_export_format" {
  let times = [0.0, 1.0]
  let values = [100.0, 105.5]
  let path = @core.SimPath::new(times, values)
  let csv = @audit.export_path_csv(path)
  assert_true(csv.length() > 0)
}

///|
test "json_export_format" {
  let opt_res : @pricing.OptionPriceResult = {
    price: 10.5,
    standard_error: 0.1,
    ci_lower: 10.3,
    ci_upper: 10.7,
  }
  let json = @audit.export_option_result_json(opt_res, "European Call")
  assert_true(json.length() > 0)
}

///|
test "markdown_executive_report_generation" {
  let pm = @core.PathMatrix::new(2, 2)
  let audit = @audit.AuditTrail::new(999UL, 2, 2, pm)
  let opt_res : @pricing.OptionPriceResult = {
    price: 12.0,
    standard_error: 0.2,
    ci_lower: 11.6,
    ci_upper: 12.4,
  }
  let var_res = @risk.compute_parametric_var(0.95, 0.05, 0.2)
  let report = @audit.generate_executive_report(
    "Portfolio Risk", audit, opt_res, var_res,
  )
  assert_true(report.length() > 0)
}
