defmodule Elbe.Strategies.TwoRandom do
  @behaviour Elbe.Strategy

  def get_host(hosts) do
    if Enum.count(hosts) > 1 do
      [host1, host2] = Enum.take_random(hosts, 2)

      if host1.connections <= host2.connections do
        host1
      else
        host2
      end
    else
      Enum.at(hosts, 0)
    end
  end
end
