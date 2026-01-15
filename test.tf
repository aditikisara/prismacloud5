module QaTags {
  source = ""  gl_purpose     = module.static_variables.gl_purpose
  table_name     = module.templates.dynamo_table_name_qa_tags
  table_hash_key = "stack-name"
  table_rcu      = "10"
  table_wcu      = "10"
  kms_alias      = module.templates.kms_key_alias_aws_dynamodb
  extra_tags     = module.templates.qa_cost_tags
}

module QaAttributes {
  source = ""  gl_purpose     = module.static_variables.gl_purpose
  table_name     = module.templates.dynamo_table_name_qa_attributes
  table_hash_key = "instance-id"
  table_rcu      = "10"
  table_wcu      = "10"
  extra_tags     = module.templates.qa_cost_tags
  enable_point_in_time_recovery = true
  kms_alias = module.templates.kms_key_alias_aws_dynamodb
}

module qa_config {
  source = ""  table_name = "${module.env_vars.Environment}.qa.config"  table_hash_key  = "PK"
  table_range_key = "SK"  table_wcu = 1
  table_rcu = 1  global_secondary_indices = [
    {
      name            = "SwappedHashKeyRangeKeyIndex"
      hash_key        = "SK"
      range_key       = "PK"
      projection_type = "ALL"
      write_capacity  = 1
      read_capacity   = 5
    }
  ]  tags = merge(module.env_vars.base_tags, module.templates.qa_cost_tags)  resource_policy_config = {
    create = false
  }
} 

data aws_iam_policy_document dynamodb_resource_policy {
  statement {
    actions = ["dynamodb:*"]
    effect = "Allow"
    principals {
      type = "Service"
      identifiers = [
        "lambda.amazonaws.com"
      ]
    }
    condition {
      test   = "StringEquals"
      variable = "aws:SourceOrgID"
      values  = [data.aws_organizations_organization.current.id]
    }
  }  statement {
    actions = ["dynamodb:*"]
    effect = "Allow"
    principals {
      identifiers = ["arn:aws:iam::646688815978:root"]
      type = "AWS"
    }
    condition {
      test   = "StringEquals"
      variable = "aws:PrincipalOrgID"
      values  = [data.aws_organizations_organization.current.id]
    }
  }
}

resource aws_dynamodb_resource_policy attach_to_qatags  {
  policy       = data.aws_iam_policy_document.dynamodb_resource_policy.json
  resource_arn = module.QaTags.table_arn
}

resource aws_dynamodb_resource_policy attach_to_qaattributes  {
  policy       = data.aws_iam_policy_document.dynamodb_resource_policy.json
  resource_arn = module.QaAttributes.table_arn
}

resource aws_dynamodb_resource_policy attach_to_qa_config  {
  policy       = data.aws_iam_policy_document.dynamodb_resource_policy.json
  resource_arn = module.qa_config.table_arn
} 
