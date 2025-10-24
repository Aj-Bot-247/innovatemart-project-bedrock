# --- THIS FILE IS COMMENTED OUT TO "DOCUMENT THE PROCESS" ---
# --- AS I DO NOT OWN THE DOMAIN 'innovatemart-ajbot.com' ---
# --- PER BONUS OBJECTIVE 4.2 INSTRUCTIONS ---

# variable "domain_name" {
#   description = "The domain name for the application."
#   type        = string
#   default     = "innovatemart-ajbot.com" 
# }

# data "aws_route53_zone" "primary" {
#   name = var.domain_name
# }

# resource "aws_acm_certificate" "innovatemart_cert" {
#   domain_name       = var.domain_name
#   validation_method = "DNS"
# 
#   lifecycle {
#     create_before_destroy = true
#   }
# }
# 
# resource "aws_route53_record" "cert_validation" {
#   for_each = {
#     for dvo in aws_acm_certificate.innovatemart_cert.domain_validation_options : dvo.domain_name => {
#       name   = dvo.resource_record_name
#       record = dvo.resource_record_value
#       type   = dvo.resource_record_type
#     }
#   }
#   allow_overwrite = true
#   name            = each.value.name
#   records         = [each.value.record]
#   ttl             = 60
#   type            = each.value.type
#   zone_id         = data.aws_route53_zone.primary.zone_id
# }
# 
# resource "aws_acm_certificate_validation" "innovatemart_cert_validation" {
#   certificate_arn         = aws_acm_certificate.innovatemart_cert.arn
#   validation_record_fqdns = [for record in aws_route53_record.cert_validation : record.fqdn]
# }