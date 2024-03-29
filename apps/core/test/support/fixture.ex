defmodule Core.Fixture do
  def cog_string_valid do
    %{
      name: "merchant_email_receiver_STR",
      value: "ops@example.com",
      datatype: "string",
      namespace: "default"
    }
  end

  def schema_object do
    %{
      name: "sample_schema",
      value: """
      {
        "type" : "object",
        "properties" : {
          "name" : {"type" : "string"},
          "attr_number" : {"type": "integer"}
        }
      }
      """
    }
  end

  def schema_generic_number_above_100 do
    %{
      name: "genric.number",
      value: """
      {
        "type" : "number",
        "minimum" : 100
      }
      """
    }
  end

  def cog_object_valid do
    %{
      name: "merchant_email_receiver",
      value: """
      {
        "name" : "credit_card",
        "attr_number" : 1
      }
      """,
      datatype: "object",
      namespace: "default",
      schema: "sample_schema"
    }
  end

  def cog_object_json_schema_invalid do
    %{
      name: "merchant_email_receiver",
      value: """
      {
        "name" : "credit_card",
        "attr_number" : "2"
      }
      """,
      datatype: "object",
      namespace: "default",
      schema: "sample_schema"
    }
  end

  def col_valid do
    %{
      name: "coll_config_a",
      namespace: "default",
      desc: "a collection config for a"
    }
  end
end
