output "alb_dns_name" { value = aws_lb.alb.dns_name }
output "alb_zone_id" { value = aws_lb.alb.zone_id }
output "alb_sg_id" { value = aws_security_group.alb_sg.id }
output "target_group_arn" { value = aws_lb_target_group.tg.arn }
output "lb_arn_suffix" { value = aws_lb.alb.arn_suffix }
output "tg_arn_suffix" { value = aws_lb_target_group.tg.arn_suffix }