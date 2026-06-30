defmodule Elbe.Host do
  @derive JSON.Encoder
  defstruct [:host, :port, connections: 0]

  @type t :: %__MODULE__{host: binary, port: integer, connections: non_neg_integer()}

  def new(args) do
    struct(__MODULE__, args)
  end
end
