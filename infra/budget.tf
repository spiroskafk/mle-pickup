# Billing budget with alert thresholds — the safety net against runaway costs
# (e.g. a buggy function looping, or an abused endpoint). Google can't hard-cap
# spend, but this emails you well before anything meaningful is charged.
#
# Only created when a billing account is attached (i.e. at `apply` time, not on
# a billing-less `plan`).

resource "google_billing_budget" "monthly" {
  count = var.billing_account != "" ? 1 : 0

  billing_account = var.billing_account
  display_name    = "MLE ${var.environment} monthly budget"

  budget_filter {
    projects = ["projects/${google_project.mle.number}"]
  }

  amount {
    specified_amount {
      currency_code = "EUR"
      units         = var.budget_amount_eur
    }
  }

  # Alert at 50% / 90% / 100% of the threshold.
  threshold_rules {
    threshold_percent = 0.5
  }
  threshold_rules {
    threshold_percent = 0.9
  }
  threshold_rules {
    threshold_percent = 1.0
  }

  dynamic "all_updates_rule" {
    for_each = length(var.budget_alert_emails) > 0 ? [1] : []
    content {
      monitoring_notification_channels = [
        for c in google_monitoring_notification_channel.email : c.id
      ]
      disable_default_iam_recipients = true
    }
  }
}

resource "google_monitoring_notification_channel" "email" {
  for_each = var.billing_account != "" ? toset(var.budget_alert_emails) : []

  project      = google_project.mle.project_id
  display_name = "MLE budget alert (${each.value})"
  type         = "email"

  labels = {
    email_address = each.value
  }

  depends_on = [google_project_service.apis]
}
