defmodule Elbe.Host do
  @derive JSON.Encoder
  defstruct [:host, :port, connections: 0]

  def load(%__MODULE__{} = host) do
    host.connections
  end
end
