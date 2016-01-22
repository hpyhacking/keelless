defmodule Keelless.Project do
  use HTTPoison.Base
  use GenServer

  @base_path "https://api.keen.io/3.0"

  #############################################################################
  ### GenServer Callback
  #############################################################################

  def start_link(project_id, write_key) do
    opts  = [name: project_id_to_process_id(project_id)]

    config = %{project_id: project_id, write_key: write_key, error: nil}
    config = config |> Dict.merge(record_builder(config))

    GenServer.start_link(__MODULE__, config, opts)
  end

  def init(config) do
    {:ok, config}
  end

  def handle_call({:sync, collection, data} _, config) do
    result = 
      config.record_single.(collection, data)
      |> gogogo!

    {:reply, result, config}
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

      req = %{uri: uri, verb: :post, timeout: 10000, sync: true, headers: headers}

      case Poison.encode(payload) do
        {:ok, data} -> Dict.put(req, :payload, data)
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
  defp gogogo!(req = %{uri: uri, verb: :post, payload: payload, headers: headers}) do
    post(uri, payload, headers, [{:timeout, timeout}, {:recv_timeout, timeout}])
    |> process_response(req)
  end

  defp process_response(response, request) do
    case response do
      {:ok, %{status_code: 200, body: body}} -> {:ok, body}
      {:ok, %{status_code: 201, body: body}} -> {:ok, body}
      {:ok, %{status_code: code, body: body}} ->
        {:error, %{status_code: code}}
      {:error, reason} ->
        {:error, %{error: :client_error, reason: reason}}
    end
  end

  defp project_id_to_process_id(project_id) do
    String.to_atom "#{project_id}.keenio.com"
  end
end

