defmodule HttpApi.TestUtils do
  use Plug.Test
  @opts HttpApi.Endpoints.init([])
  def make_call(method, path, body) do
    conn = conn(method, path, body)
    conn = HttpApi.Endpoints.call(conn, @opts)
    {conn.status, conn.resp_body}
  end
end