defmodule ActiveProxyTest do
  use ExUnit.Case
  doctest ActiveProxy

  test "greets the world" do
    assert ActiveProxy.hello() == :world
  end
end
