defmodule Elbe.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  @impl true
  def start(_type, _args) do
    children = [
      # Starts a worker by calling: Elbe.Worker.start_link(arg)
      # {Elbe.Worker, arg}
      {Elbe.HostState,
       %{
         hosts: [
           %{host: "localhost", port: 4002}
           #  %Elbe.Host{host: "localhost", port: 4003},
           #  %Elbe.Host{host: "localhost", port: 4004},
           #  %Elbe.Host{host: "localhost", port: 4005},
           #  %Elbe.Host{host: "localhost", port: 4006},
           #  %Elbe.Host{host: "localhost", port: 4007}
         ]
       }},
      {Bandit, plug: Elbe.Router, scheme: :http, port: 4001}
    ]

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: Elbe.Supervisor]
    Supervisor.start_link(children, opts)
  end
end
