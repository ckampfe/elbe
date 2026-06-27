defmodule Elbe.Strategy do
  alias Elbe.Host

  @callback get_host(%{hosts: map}) :: Host.t()
end
