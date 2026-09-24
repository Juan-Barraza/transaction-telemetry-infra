resource "aws_dynamodb_table" "telemetry_events" {
  name         = "${var.project_name}-telemetry-events-${var.environment}"
  billing_mode = var.billing_mode
  hash_key     = var.hash_key
  range_key    = var.range_key

  attribute {
    name = var.hash_key
    type = "S"
  }

  attribute {
    name = var.range_key
    type = "S"
  }

  tags = {
    Name        =  var.tags_dynamodb[0]
    Environment = var.tags_dynamodb[1]
    Region      = var.tags_dynamodb[2]
  }
}
