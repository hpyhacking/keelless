defmodule KeellessTest do
  use ExUnit.Case, async: true

  setup do
    {:ok, _} = Keelless.start_link(:test)
    {:ok, name: :test}
  end

  test "publish data", %{name: name} do
    data = %{key: "keelless", val: "test", at: :os.system_time(:seconds)}
    collection = "keelless"
    assert :ok == Keelless.publish(name, collection, data)
  end
end
