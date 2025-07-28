resource "aws_lex_bot" "product_search" {
  name                        = "${var.bot_name}"
  description                 = "${var.bot_description}"
  child_directed              = false
  process_behavior            = "BUILD"
  idle_session_ttl_in_seconds = var.idle_session_ttl

  abort_statement {
    message {
      content      = var.abort_message
      content_type = "PlainText"
    }
  }

  intent {
    intent_name    = aws_lex_intent.product_search.name
    intent_version = "$LATEST"
  }

  clarification_prompt {
    max_attempts = var.clarification_attempts
    message {
      content      = var.clarification_message
      content_type = "PlainText"
    }
  }
}

resource "aws_lex_intent" "product_search" {
  name        = "${var.bot_name}-intent"
  description = "Intent for searching products"

  sample_utterances = var.sample_utterances

  fulfillment_activity {
    type = "ReturnIntent"
  }

  slot {
    name         = "productsName"
    description  = "The name of the product to search for"
    slot_constraint = "Required"
    slot_type    = var.slot_type
    value_elicitation_prompt {
      max_attempts = 2
      message {
        content      = var.slot_prompt
        content_type = "PlainText"
      }
    }
  }
}