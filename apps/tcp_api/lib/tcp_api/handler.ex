defmodule TcpApi.Handler do
  require Logger

  def start_link(ref, transport, opt) do
    pid = spawn_link(__MODULE__, :init, [ref, transport, opt])
    {:ok, pid}
  end

  def init(ref, transport, _opt=[]) do
    {:ok, socket} = :ranch.handshake(ref)

    case transport.peername(socket) do
      {:ok, _peer} -> loop(socket, transport, "")
      {:error, reason} -> Logger.error("[tcp.handler] init receive error reason: #{inspect(reason)}")
    end
  end

  def loop(socket, transport, acc) do
    transport.setopts(socket, [active: :once])
    {ok, closed, error, passive} = transport.messages()
    receive do
      {'EXIT', parent, reason} ->
        Logger.error("[tcp.handler] exit parent reason: #{inspect(reason)}")
        Process.exit(self(), :kill)
      {:error, reason} ->
        Logger.error("[tcp.handler] error: #{inspect(reason)}")
      {^ok, socket, data} ->
        Logger.debug("[tcp.handler] ok: #{inspect(ok)} received data: #{inspect(data)}")
        acc <> data
        |> String.split("\n")
        |> Enum.map(&(String.trim(&1)))
        |> _process(socket, transport)
        loop(socket, transport, "")
      {^closed, socket} ->
        Logger.debug("[tcp.handler] closed socket: #{inspect(socket)}")
      {^error, socket, reason} ->
        Logger.error("[tcp.handler] socket: #{inspect(socket)}, closed becaose of the error reason: #{inspect(reason)}")
      message ->
        Logger.debug("[tcp.handler] message on receive block: #{inspect(message)}")
    end
  end

  defp _kill(), do: Process.exit(self(), :kill)

  defp _process([], socket, transport), do: loop(socket, transport, "")
  defp _process([""], socket, transport), do: loop(socket, transport, "")
  defp _process([line, ""], socket, transport) do
    _protocol(line, socket, transport)
    loop(socket, transport, "")
  end
  defp _process([line], socket, transport), do: loop(socket, transport, line)
  defp _process([line | lines], socket, transport) do
    _protocol(line, socket, transport)
    _process(lines, socket, transport)
  end

  defp _protocol(line, socket, transport) do
    Logger.debug("[_protocol] line: #{line}")

    case line |> TcpApi.Protocol.process do
      {:reply, message} -> _reply(transport, socket, message)
      {:reply_exit, message} ->
        _reply(transport, socket, message)
        _kill()
      {:error, reason} ->
        Logger.error("[tcp] #{inspect(reason)}")
      :error ->
        Logger.error("error on processing: #{inspect(line)}")
      :exit ->
        Logger.info("[tcp] client exit")
        _kill()
      _ -> :ok
    end
  end

  defp _reply(transport, socket, message) do
    case transport.send(socket, "#{message}\n") do
      {:error, reason} ->
        Logger.error(inspect(reason))
      _ -> :ok
    end
  end
end