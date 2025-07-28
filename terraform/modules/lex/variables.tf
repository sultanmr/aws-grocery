variable "bot_name" {
  description = "Name of the Lex bot"
  type        = string
}

variable "bot_description" {
  description = "Description of the Lex bot"
  type        = string
  default     = "Bot for searching products"
}

variable "idle_session_ttl" {
  description = "TTL in seconds for idle sessions"
  type        = number
  default     = 300
}

variable "abort_message" {
  description = "Message to display when aborting"
  type        = string
  default     = "Sorry, I couldn't understand. Please try again."
}

variable "clarification_attempts" {
  description = "Max attempts for clarification prompts"
  type        = number
  default     = 2
}

variable "clarification_message" {
  description = "Message for clarification prompts"
  type        = string
  default     = "I didn't understand you. Could you please rephrase?"
}

variable "sample_utterances" {
  description = "List of sample utterances for the intent"
  type        = list(string)
  default     = [
    "I'm looking for {productsName}",
    "Find me {productsName}",
    "Show me {productsName}",
    "Do you have {productsName}",
    "Search for {productsName}"
  ]
}

variable "slot_type" {
  description = "Slot type for product name"
  type        = string
  default     = "AMAZON.Fruit"
}

variable "slot_prompt" {
  description = "Prompt message for slot value elicitation"
  type        = string
  default     = "What product would you like to search for?"
}