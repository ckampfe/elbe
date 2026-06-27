defmodule Elbe.Strategy do
  @callback get_host(%{hosts: map}) :: map
end
