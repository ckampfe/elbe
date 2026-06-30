defmodule Elbe.Router do
  use Plug.Router

  alias Elbe.HostState

  require Logger

  plug(Plug.Logger, log: :debug)
  plug(:match)
  plug(:dispatch)

  get "/state" do
    state = :sys.get_state(HostState)
    send_resp(conn, 200, JSON.encode_to_iodata!(state))
  end

  match _ do
    strategy = Elbe.Strategies.TwoRandom

    {host, ref} = HostState.get_host(strategy)

    Logger.debug("Selected #{inspect(host)} using strategy #{strategy}")

    {:ok, conn, response} = forward_request(conn, host)

    conn =
      Enum.reduce(response.headers, conn, fn {key, value}, acc ->
        put_resp_header(acc, key, value)
      end)

    Logger.debug("FROM FORWARDED #{inspect(host)}: received response #{response.body}")

    conn = send_resp(conn, response.status, response.body)

    HostState.return_host(ref)

    conn
  end

  defp forward_request(conn, host) do
    {:ok, body, conn} = read_request_body(conn)

    Logger.debug("FROM CLIENT: received #{body}")

    {:ok, fwd_conn} = Mint.HTTP.connect(:http, host.host, host.port)

    {:ok, fwd_conn, _req_ref} =
      Mint.HTTP.request(
        fwd_conn,
        conn.method,
        conn.request_path,
        conn.req_headers,
        body || ""
      )

    Logger.debug(
      "TO FORWARDED: sent #{body} to #{conn.method} #{host.host}:#{host.port}#{conn.request_path}"
    )

    response = build_response(fwd_conn)

    {:ok, conn, response}
  end

  defp build_response(fwd_conn) do
    build_response(fwd_conn, %{status: nil, headers: [], body: ""})
  end

  defp build_response(fwd_conn, resp) do
    # these matches are recommended by bandit:
    # https://bandit.hexdocs.pm/Bandit.html#module-receiving-messages-in-your-plug-process-a-word-of-warning
    receive do
      message
      when not (is_tuple(message) and tuple_size(message) == 2 and elem(message, 0) == :bandit and
                    message != {:plug_conn, :sent}) ->
        {:ok, _fwd_conn, responses} = Mint.HTTP.stream(fwd_conn, message)

        Enum.reduce(responses, resp, fn
          {:status, _ref, status}, acc ->
            %{acc | status: status}

          {:headers, _ref, headers}, acc ->
            %{acc | headers: headers}

          {:data, _ref, data}, acc ->
            %{acc | body: acc.body <> data}

          {:done, _ref}, acc ->
            acc
        end)
    end
  end

  defp read_request_body(conn) do
    read_request_body(conn, "")
  end

  defp read_request_body(conn, buf) do
    case Plug.Conn.read_body(conn) do
      {:ok, body, conn} ->
        {:ok, buf <> body, conn}

      {:more, body, conn} ->
        read_request_body(conn, buf <> body)
    end
  end
end
