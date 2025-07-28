output "bot_name" {
  description = "Name of the created Lex bot"
  value       = aws_lex_bot.product_search.name
}

output "bot_arn" {
  description = "ARN of the created Lex bot"
  value       = aws_lex_bot.product_search.arn
}

output "intent_name" {
  description = "Name of the created Lex intent"
  value       = aws_lex_intent.product_search.name
}