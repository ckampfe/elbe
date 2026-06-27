defmodule Elbe.Strategies.TwoRandom do
  @behaviour Elbe.Strategy

  alias Elbe.Host

  def get_host(%{hosts: hosts}) do
    if Enum.count(hosts) > 1 do
      [host1, host2] = Enum.take_random(hosts, 2)

      if Host.load(host1) <= Host.load(host2) do
        host1
      else
        host2
      end
    else
      Enum.at(hosts, 0)
    end
  end
end
