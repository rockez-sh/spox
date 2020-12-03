defmodule Core.ConfigTest do
  alias Core.Config
  alias Core.Model
  use Core.DataCase
  alias Core.Repo

  test "validate attrs" do
    fixture = %{
      name: "merchant_email_receiver",
      value: "ops@example.com",
      datatype: "string"
    }

    {:error, x} = Config.create(fixture)
    assert x == "namespace must be defined"
  end

  test "define default value" do
    fixture = %{
      name: "merchant_email_receiver",
      value: "ops@example.com",
      datatype: "string",
      namespace: "default"
    }

    {:ok, cs} =  Config.create(fixture)
    assert cs.version > 0
    assert cs.latest == true
    assert cs.inserted_at > 0
  end

  test "promote new version" do

    fixture1 = %{
      name: "merchant_email_receiver",
      value: "ops@example.com",
      datatype: "string",
      namespace: "default"
    }
    {:ok, cs1} =  Config.create(fixture1)

    fixture1a = %{
      name: "merchant_email_receiver_weekday",
      value: "ops@example.com",
      datatype: "string",
      namespace: "default"
    }
    {:ok, cs1a} =  Config.create(fixture1a)

    fixture2 = %{
      name: "merchant_email_receiver",
      value: "ops@opay.com",
      datatype: "string",
      namespace: "default"
    }

    {:ok, cs2} =  Config.create(fixture2)

    old_version = Repo.get_by(Core.Model.Config, id: cs1.id)
    another_config = Repo.get_by(Core.Model.Config, id: cs1a.id)

    assert cs1.version < cs2.version
    assert cs2.latest == true
    assert old_version.latest == false
    assert another_config.latest == true
  end

  test "validate with schema" do
    fixture_schema = %{
      name: "sample_schema" ,
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
    {:ok, schema_cs} = %Model.Schema{}
      |> Model.Schema.changeset(fixture_schema)
      |> Repo.insert()

    fixture_valid_config = %{
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
    {:ok, cfg} = Config.create(fixture_valid_config)
    assert cfg.schema_id == schema_cs.id

    fixture_invalid_config = %{
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
    assert {:error, "invalid payload agains json schema"} == Config.create(fixture_invalid_config)
    assert {:error, "Cannot find the schema"} == fixture_invalid_config
    |> Map.put(:schema, "not_exist_schema")
    |> Config.create()
  end
end