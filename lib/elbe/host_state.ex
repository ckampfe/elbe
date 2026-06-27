defimpl JSON.Encoder, for: MapSet do
  def encode(value, _encoder) do
    JSON.encode!(MapSet.to_list(value))
  end
end

defmodule Elbe.HostState do
  use GenServer

  @derive JSON.Encoder
  defstruct [:hosts, :last_selected]

  def start_link(%{hosts: _hosts} = args) do
    GenServer.start_link(__MODULE__, args, name: __MODULE__)
  end

  def init(args) do
    {:ok, struct(__MODULE__, args)}
  end

  def get_host(strategy) do
    GenServer.call(__MODULE__, {:get_host, strategy})
  end

  def return_host(closed_host) do
    GenServer.cast(__MODULE__, {:return_host, closed_host})
  end

  def handle_call({:get_host, strategy}, {_caller_pid, _ref} = _from, state) do
    host = strategy.get_host(state)

    hosts = MapSet.delete(state.hosts, host)

    host = Map.update!(host, :connections, &(&1 + 1))

    hosts = MapSet.put(hosts, host)

    state = %{state | hosts: hosts, last_selected: host}

    {:reply, host, state}
  end

  def handle_cast({:return_host, closed_host}, state) do
    without =
      state.hosts
      |> MapSet.to_list()
      |> Enum.filter(fn host ->
        host != closed_host
      end)
      |> MapSet.new()

    updated = Map.update!(closed_host, :connections, &(&1 - 1))

    hosts = MapSet.put(without, updated)

    {:noreply, Map.put(state, :hosts, hosts)}
  end
end
