resource "aws_cloudwatch_dashboard" "dash" {
  dashboard_name = "${var.project}-dashboard"
  dashboard_body = templatefile(var.dashboard_json_path, {
    region        = var.region
    cluster_name  = var.cluster_name
    service_name  = var.service_name
    lb_arn_suffix = var.lb_arn_suffix
    tg_arn_suffix = var.tg_arn_suffix
  })
}

resource "aws_cloudwatch_metric_alarm" "cpu_high" {
  alarm_name          = "${var.project}-cpu-high"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 2
  metric_name         = "CPUUtilization"
  namespace           = "AWS/ECS"
  period              = 60
  statistic           = "Average"
  threshold           = var.cpu_alarm_threshold

  dimensions = {
    ClusterName = var.cluster_name
    ServiceName = var.service_name
  }
}

resource "aws_cloudwatch_metric_alarm" "unhealthy_hosts" {
  alarm_name          = "${var.project}-unhealthy-hosts"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 2
  metric_name         = "UnHealthyHostCount"
  namespace           = "AWS/ApplicationELB"
  period              = 60
  statistic           = "Average"
  threshold           = 0

  dimensions = {
    TargetGroup  = var.tg_arn_suffix
    LoadBalancer = var.lb_arn_suffix
  }
}