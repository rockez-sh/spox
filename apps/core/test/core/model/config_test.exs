defmodule Core.Model.ConfigTest do
  use Core.DataCase

  test "uniquness name vs version" do
    fixture = %{
      name: "sample.merchant_email_receiver",
      value: "ops@example.com",
      version: 1,
      datatype: "string",
      latest: true,
      namespace: "default"
    }

    {:ok, _} =  %Core.Model.Config{}
    |> Core.Model.Config.changeset(fixture)
    |> Core.Repo.insert()

    assert Core.Repo.one(from p in Core.Model.Config, select: count(p.id)) == 1

    {:error, cs} = %Core.Model.Config{}
    |> Core.Model.Config.changeset(fixture)
    |> Core.Repo.insert()

    assert %{name: ["has already been taken"]} == errors_on(cs)
  end
end