

resource "aws_cloudwatch_event_rule" "main" {
  name                = var.rule_name
  description         = var.description
  schedule_expression = var.schedule_expression
  state               = var.is_enabled ? "ENABLED" : "DISABLED"

  tags = merge(var.tags, {
    Name = var.rule_name
  })
}

resource "aws_cloudwatch_event_target" "lambda" {
  rule      = aws_cloudwatch_event_rule.main.name
  target_id = "${var.rule_name}-target"
  arn       = var.target_lambda_arn

  retry_policy {
    maximum_event_age_in_seconds = var.max_event_age_seconds
    maximum_retry_attempts       = var.max_retry_attempts
  }

  dynamic "dead_letter_config" {
    for_each = var.dlq_arn != null ? [1] : []
    content {
      arn = var.dlq_arn
    }
  }

  # Sin "input": EventBridge entrega el evento programado por defecto
  # (time, id, source=aws.events, resources=[rule_arn]). El placeholder
  # anterior (${aws.scheduler.scheduled-time}) no era una variable válida.
}

resource "aws_lambda_permission" "eventbridge" {
  statement_id  = "AllowEventBridgeInvoke-${var.rule_name}"
  action        = "lambda:InvokeFunction"
  function_name = var.target_lambda_function_name
  principal     = "events.amazonaws.com"
  source_arn    = aws_cloudwatch_event_rule.main.arn
}

resource "aws_cloudwatch_metric_alarm" "failed_invocations" {
  count               = var.create_alarm ? 1 : 0
  alarm_name          = "${var.rule_name}-failed-invocations"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 1
  metric_name         = "FailedInvocations"
  namespace           = "AWS/Events"
  period              = 300
  statistic           = "Sum"
  threshold           = 0
  alarm_description   = "EventBridge rule ${var.rule_name} has failed invocations"

  dimensions = {
    RuleName = aws_cloudwatch_event_rule.main.name
  }

  tags = var.tags
}
