resource "aws_glue_catalog_database" "athena_database" {
  name = "github_webhooks_db"
}

resource "aws_athena_workgroup" "primary" {
  name = "primary"

  configuration {
    result_configuration {
      output_location = "s3://${aws_s3_bucket.github_webhook_bucket.id}/athena_results/"
    }
  }
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
      name = "added"
      type = "array<string>"
    }

    columns {
      name = "removed"
      type = "array<string>"
    }

    columns {
      name = "modified"
      type = "array<string>"
    }
  }
}

# AWS Athena Query example:
#
#
#SELECT repository, added, removed, modified
#FROM github_webhooks_table
#LIMIT 10;


