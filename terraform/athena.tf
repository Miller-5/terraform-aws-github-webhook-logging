resource "aws_glue_catalog_database" "athena_database" {
  name = "github_webhooks_db"
}

resource "aws_athena_workgroup" "github_webhook" {
  name = "github_webhook"

  configuration {
    result_configuration {
      output_location = "s3://${aws_s3_bucket.github_webhook_bucket.id}/athena_results/"
    }
  }

  state = "ENABLED"
}

resource "aws_glue_catalog_table" "github_webhooks_table" {
  name          = "github_webhooks_table"
  database_name = aws_glue_catalog_database.athena_database.name

  table_type = "EXTERNAL_TABLE"

  parameters = {
    classification = "json"
  }

  storage_descriptor {
    location = "s3://${aws_s3_bucket.github_webhook_bucket.id}/github-webhook/"
    input_format  = "org.apache.hadoop.mapred.TextInputFormat"
    output_format = "org.apache.hadoop.hive.ql.io.HiveIgnoreKeyTextOutputFormat"
    ser_de_info {
      serialization_library = "org.openx.data.jsonserde.JsonSerDe"
    }

    columns {
      name = "repository"
      type = "string"
    }

    columns {
      name = "changed_files"
      type = "struct<added:array<string>,removed:array<string>,modified:array<string>>"
    }
  }
}

# AWS Athena Query example:
#
#
# SELECT 
#   repository, 
#   changed_files.added, 
#   changed_files.removed, 
#   changed_files.modified 
# FROM github_webhooks_table
# LIMIT 10;

# Example to use with AWS CLI:
#
# Run the query:
# aws athena start-query-execution   --query-string "SELECT repository, changed_files.added, changed_files.removed, changed_files.modified FROM github_webhooks_table LIMIT 10;"   --query-execution-context Database=github_webhooks_db   --work-group github_webhook
# 
# Get query results:
# aws athena get-query-results --query-execution-id [QUERY_EXECUTION_ID_FROM_PREVIOUS_COMMAND]
