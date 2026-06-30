defmodule Elbe.Strategy do
  alias Elbe.Host

  @callback get_host(list(Host.t())) :: Host.t()
end
