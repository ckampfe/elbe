defmodule Elbe.HostState do
  alias Elbe.Host
  use GenServer

  require Logger

  @derive JSON.Encoder
  defstruct [:hosts, :last_selected, monitors: %{}]

  def start_link(%{hosts: _hosts} = args) do
    GenServer.start_link(__MODULE__, args, name: __MODULE__)
  end

  def init(args) do
    args = %{args | hosts: Map.new(args.hosts, fn host -> {host, Host.new(host)} end)}
    {:ok, struct(__MODULE__, args)}
  end

  def get_host(strategy) do
    GenServer.call(__MODULE__, {:get_host, strategy})
  end

  def return_host(ref) do
    GenServer.call(__MODULE__, {:return_host, ref})
  end

  def handle_call({:get_host, strategy}, {caller_pid, _ref} = _from, state) do
    ref = Process.monitor(caller_pid)

    host =
      state.hosts
      |> Map.values()
      |> strategy.get_host()

    state = %{
      state
      | hosts:
          update_in(
            state.hosts,
            [
              Access.key!(Map.take(host, [:host, :port])),
              Access.key!(:connections)
            ],
            &(&1 + 1)
          ),
        last_selected: host,
        monitors: Map.put(state.monitors, ref, host)
    }

    {:reply, {host, ref}, state}
  end

  def handle_call({:return_host, ref}, {caller_pid, _ref} = _from, state) do
    state =
      if host = Map.get(state.monitors, ref) do
        Logger.debug("#{inspect(host)} returned host cleanly, demonitoring")
        Process.demonitor(ref, [:flush])
        %{state | monitors: Map.delete(state.monitors, caller_pid)}
      else
        state
      end

    state =
      update_in(
        state,
        [
          Access.key!(:hosts),
          Access.key!(Map.take(host, [:host, :port])),
          Access.key!(:connections)
        ],
        &(&1 - 1)
      )

    {:reply, :ok, state}
  end

  def handle_info({:DOWN, ref, :process, pid, _reason}, state) do
    host = get_in(state, [Access.key!(:monitors), ref])

    Logger.debug("#{inspect(pid)} crashed, removing #{inspect(host)} from monitors")

    state =
      state
      |> Map.update!(:monitors, fn monitors ->
        Map.delete(monitors, ref)
      end)
      |> update_in(
        [
          Access.key!(:hosts),
          Access.key!(Map.take(host, [:host, :port])),
          Access.key!(:connections)
        ],
        &(&1 - 1)
      )

    {:noreply, state}
  end
end
