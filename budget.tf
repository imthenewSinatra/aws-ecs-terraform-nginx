resource "aws_budgets_budget" "zero_spend" {
  name              = "Zero-Spend-Budget-Alert"
  budget_type       = "COST"
  limit_amount      = "0.01"
  limit_unit        = "USD"
  time_unit         = "MONTHLY"
  time_period_start = "2026-01-01_00:00"

  notification {
    comparison_operator        = "GREATER_THAN"
    threshold                  = 100
    threshold_type             = "PERCENTAGE"
    notification_type          = "ACTUAL"
    subscriber_email_addresses = var.budget_emails
  }
}