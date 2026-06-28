Mix.install([:plug, :bandit])

# taken from Plug itself and modified so that we can
# log the port number of each server as well
defmodule EchoServer.Logger do
  @moduledoc """
  A plug for logging basic request information in the format:

      GET /index.html
      Sent 200 in 572ms

  To use it, just plug it into the desired module.

      plug Plug.Logger, log: :debug

  ## Options

    * `:log` - The log level at which this plug should log its request info.
      Default is `:info`.
      The [list of supported levels](https://hexdocs.pm/logger/Logger.html#module-levels)
      is available in the `Logger` documentation.

  """

  require Logger
  alias Plug.Conn
  @behaviour Plug

  @impl true
  def init(opts) do
    Keyword.get(opts, :log, :info)
  end

  @impl true
  def call(conn, level) do
    Logger.log(level, fn ->
      [conn.method, ?\s, conn.request_path]
    end)

    start = System.monotonic_time()

    Conn.register_before_send(conn, fn conn ->
      Logger.log(level, fn ->
        stop = System.monotonic_time()
        diff = System.convert_time_unit(stop - start, :native, :microsecond)
        status = Integer.to_string(conn.status)
        %{port: port} = Plug.Conn.get_sock_data(conn)

        ["#{port}", ?\s, connection_type(conn), ?\s, status, " in ", formatted_diff(diff)]
      end)

      conn
    end)
  end

  defp formatted_diff(diff) when diff > 1000, do: [diff |> div(1000) |> Integer.to_string(), "ms"]
  defp formatted_diff(diff), do: [Integer.to_string(diff), "µs"]

  defp connection_type(%{state: :set_chunked}), do: "Chunked"
  defp connection_type(_), do: "Sent"
end

defmodule EchoServer do
  use Plug.Router

  require Logger

  plug(EchoServer.Logger, log: :debug)
  plug(:match)
  plug(:dispatch)

  match _ do
    {:ok, body, conn} = Plug.Conn.read_body(conn)

    Logger.debug("received #{body}")

    # sleep_time = :rand.uniform(:timer.seconds(5)) + :timer.seconds(5)
    # sleep_time = :timer.seconds(8)

    # Logger.debug("sleeping for #{sleep_time}ms and then responding")

    # Process.sleep(sleep_time)

    send_resp(conn, 200, body)
  end
end

require Logger

base_port = System.fetch_env!("PORT") |> String.to_integer()
n = System.get_env("N", "0") |> String.to_integer()

servers =
  base_port..(base_port + n)
  |> Enum.map(fn port ->
    {Bandit, plug: EchoServer, scheme: :http, port: port}
  end)

{:ok, _} = Supervisor.start_link(servers, strategy: :one_for_one)

Process.sleep(:infinity)
