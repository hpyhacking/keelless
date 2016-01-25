defmodule Keelless.Project do
  use HTTPoison.Base
  use GenServer

  @base_path "https://api.keen.io/3.0"
  @request_opts [{:timeout, 10000}, {:recv_timeout, 10000}]

  #############################################################################
  ### GenServer Callback
  #############################################################################

  def start_link(name, project_id, write_key) do
    config = %{project_id: project_id, write_key: write_key, error: nil}
    config = config |> Dict.merge(record_builder(config))

    GenServer.start_link(__MODULE__, config, [name: name])
  end

  def init(config) do
    {:ok, config}
  end

  def handle_cast({:publish, collection, data}, config) do
    {:ok, _} = 
      config.record_single.(collection, data)
      |> gogogo!

    {:noreply, config}
  end

  #############################################################################
  ### HTTPoison Callback and Helper
  #############################################################################

  defp process_response_body(body) do
    body |> Poison.decode!
  end

  #############################################################################
  ### Helper and Private
  #############################################################################

  defp record_builder(%{project_id: project_id, write_key: write_key}) do
    record_single_builder = fn collection_name, data ->
      uri = @base_path <> "/projects/#{project_id}/events/#{collection_name}"
      headers = [{"Authorization", write_key}, {"Content-Type", "application/json"}]

      req = %{uri: uri, verb: :post, sync: true, headers: headers}

      case Poison.encode(data) do
        {:ok, encoded_data} -> Dict.put(req, :payload, encoded_data)
        _ -> {:error, {:invalid_data, data}}
      end
    end

    record_signle_async_builder = fn collection_name, data ->
      record_single_builder.(collection_name, data)
      |> Dict.put(:sync, false)
    end

    %{record_single: record_single_builder, record_signle_async: record_signle_async_builder}
  end

  defp gogogo!(error = {:error, _}), do: error
  defp gogogo!(%{uri: uri, verb: :post, payload: payload, headers: headers}) do
    post(uri, payload, headers, @request_opts)
    |> process_response
  end

  defp process_response(response) do
    case response do
      {:ok, %{status_code: 200, body: body}} -> {:ok, body}
      {:ok, %{status_code: 201, body: body}} -> {:ok, body}
      {:error, reason} -> {:error, %{error: :client_error, reason: reason}}
    end
  end
end

