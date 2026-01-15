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

