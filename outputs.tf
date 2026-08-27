output "alarm_sns_topic_arn" {
  description = "ARN of the SNS topic used for NAT instance health alarms (either the module-created topic or the one provided via var.alarm_sns_topic_arn). Null if alarms are disabled. Note: email subscriptions added via var.alarm_email_addresses require manual confirmation via the link sent to each address."
  value       = local.alarm_topic_arn
}
