Mix.install([:plug, :bandit])

defmodule Echo do
  use Plug.Router

  require Logger

  plug(Plug.Logger, log: :debug)
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

port = System.fetch_env!("PORT")
port = String.to_integer(port)

require Logger
webserver = {Bandit, plug: Echo, scheme: :http, port: port}
{:ok, _} = Supervisor.start_link([webserver], strategy: :one_for_one)
Logger.info("Plug now running on localhost:#{port}")
Process.sleep(:infinity)
