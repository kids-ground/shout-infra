output "url" {
  value = aws_apigatewayv2_stage.stage.invoke_url
}

output "endpoint" {
  value = aws_apigatewayv2_api.api_gateway.api_endpoint
}