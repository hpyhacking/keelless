defmodule Keelless do
  def start_link(name) do
    project_id = take_env(name, "project_id")
    write_key = take_env(name, "write_key")
    Keelless.Project.start_link(name_to_process(name), project_id, write_key)
  end

  def publish(name, collection, data) do
    project = name_to_process(name)
    GenServer.cast(project, {:publish, collection, data})
  end

  defp take_env(name, key) do
    env_key = "#{name}_#{key}" |> String.to_atom
    case Application.get_env(:keelless, env_key) do
      nil -> raise("please set #{env_key} environment")
      val -> val
    end
  end

  defp name_to_process(name) do
    String.to_atom "#{name}.keenio.com"
  end
end
