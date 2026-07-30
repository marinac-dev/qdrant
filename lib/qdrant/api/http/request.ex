defmodule Qdrant.Api.Http.Request do
  @moduledoc """
  Shared path and query encoding helpers used by the REST endpoint modules.

      iex> Qdrant.Api.Http.Request.segment("team/a?")
      "team%2Fa%3F"

      iex> Qdrant.Api.Http.Request.query("/points", wait: false, timeout: nil)
      "/points?wait=false"
  """

  alias Qdrant.{Client, Error, Types}

  @spec segment(term()) :: String.t()
  def segment(value), do: URI.encode(to_string(value), &URI.char_unreserved?/1)

  @spec query(String.t(), keyword() | map()) :: String.t()
  def query(path, params) do
    encoded =
      params
      |> Enum.reject(fn {_key, value} -> is_nil(value) end)
      |> Enum.map(fn {key, value} -> {to_string(key), query_value(value)} end)
      |> URI.encode_query()

    cond do
      encoded == "" -> path
      String.contains?(path, "?") -> path <> "&" <> encoded
      true -> path <> "?" <> encoded
    end
  end

  @spec request(Client.t(), Tesla.Env.method(), String.t(), [Types.request_option()]) :: Types.result()
  def request(%Client{} = client, method, path, opts \\ []) do
    path = query(path, Keyword.get(opts, :query, []))
    url = client.url <> client.base_path <> path

    request_opts = [method: method, url: path]

    request_opts =
      if Keyword.has_key?(opts, :body),
        do: Keyword.put(request_opts, :body, Keyword.fetch!(opts, :body)),
        else: request_opts

    request_opts = maybe_stream_response(request_opts, client, Keyword.get(opts, :response, :auto))
    links_before = process_links()

    case Client.execute(client, request_opts) do
      {:ok, %Tesla.Env{} = env} ->
        parse_response(client, method, url, env, Keyword.get(opts, :response, :auto), links_before)

      {:error, reason} ->
        {:error, %Error{kind: decode_or_transport(reason), reason: reason, method: method, url: url}}
    end
  end

  defp parse_response(client, method, url, env, response_type, links_before) do
    headers = normalize_headers(env.headers)
    request_id = request_id(headers)

    with {:ok, body} <- consume_body(env.body, client.max_response_bytes, links_before),
         {:ok, decoded} <- decode_body(body, headers, response_type) do
      if success?(env.status) do
        {:ok, decoded}
      else
        {:error,
         %Error{
           kind: :http,
           status: env.status,
           body: decoded,
           method: method,
           url: url,
           headers: headers,
           request_id: request_id
         }}
      end
    else
      {:error, :too_large} ->
        error(:response_too_large, method, url, env, headers, request_id,
          reason: {:max_response_bytes, client.max_response_bytes}
        )

      {:error, reason, body} ->
        error(:decode, method, url, env, headers, request_id, reason: reason, body: body)
    end
  end

  defp query_value(value) when is_atom(value), do: Atom.to_string(value)
  defp query_value(value), do: value

  defp success?(status), do: status in 200..299

  defp consume_body(body, max, links_before) when is_struct(body, Stream) do
    result =
      Enum.reduce_while(body, {[], 0}, fn chunk, {chunks, size} ->
        chunk_size = IO.iodata_length(chunk)

        if size + chunk_size > max do
          {:halt, {:error, :too_large}}
        else
          {:cont, {[chunk | chunks], size + chunk_size}}
        end
      end)

    case result do
      {:error, :too_large} ->
        stop_response_tasks(links_before)
        {:error, :too_large}

      {chunks, _size} ->
        {:ok, chunks |> Enum.reverse() |> IO.iodata_to_binary()}
    end
  rescue
    error -> {:error, {:stream, error}, nil}
  end

  defp consume_body(body, max, _links_before) when is_binary(body) do
    if byte_size(body) > max, do: {:error, :too_large}, else: {:ok, body}
  end

  defp consume_body(body, max, links_before) when is_function(body, 2) do
    reducer = fn chunk, {chunks, size} ->
      chunk_size = IO.iodata_length(chunk)

      if size + chunk_size > max do
        {:halt, {:too_large, chunks, size}}
      else
        {:cont, {[chunk | chunks], size + chunk_size}}
      end
    end

    case body.({:cont, {[], 0}}, reducer) do
      {:done, {chunks, _size}} ->
        {:ok, chunks |> Enum.reverse() |> IO.iodata_to_binary()}

      {:halt, {:too_large, _chunks, _size}} ->
        stop_response_tasks(links_before)
        {:error, :too_large}

      other ->
        {:error, {:stream, other}, nil}
    end
  rescue
    error -> {:error, {:stream, error}, nil}
  end

  defp consume_body(body, _max, _links_before), do: {:ok, body}

  defp decode_body(body, headers, response_type) do
    cond do
      response_type == :binary and is_binary(body) -> {:ok, body}
      response_type == :binary -> {:error, {:unsupported_body, :binary}, body}
      response_type == :text -> {:ok, body}
      json_body?(headers, response_type) -> decode_json(body)
      response_type == :json -> {:error, {:unsupported_body, :json}, body}
      true -> {:ok, body}
    end
  end

  defp decode_json(body) when body in ["", nil], do: {:ok, body}

  defp decode_json(body) when is_binary(body) do
    case JSON.decode(body) do
      {:ok, decoded} -> {:ok, decoded}
      {:error, reason} -> {:error, reason, body}
    end
  end

  defp decode_json(body) when is_map(body) or is_list(body) or is_boolean(body) or is_number(body), do: {:ok, body}
  defp decode_json(body), do: {:error, {:unsupported_json_body, body}, body}

  defp json_body?(headers, response_type) do
    response_type == :json or
      case List.keyfind(headers, "content-type", 0) do
        {_, value} -> String.starts_with?(String.downcase(value), "application/json")
        nil -> false
      end
  end

  defp error(kind, method, url, env, headers, request_id, fields) do
    {:error,
     struct!(
       Error,
       [kind: kind, status: env.status, method: method, url: url, headers: headers, request_id: request_id] ++ fields
     )}
  end

  defp maybe_stream_response(opts, %Client{adapter: Tesla.Adapter.Finch}, response_type)
       when response_type in [:binary, :text] do
    opts
  end

  defp maybe_stream_response(opts, %Client{adapter: Tesla.Adapter.Finch}, _response_type) do
    Keyword.put(opts, :opts, adapter: [response: :stream])
  end

  defp maybe_stream_response(opts, _client, _response_type), do: opts

  defp process_links do
    case Process.info(self(), :links) do
      {:links, links} -> links
      nil -> []
    end
  end

  defp stop_response_tasks(links_before) do
    process_links()
    |> Kernel.--(links_before)
    |> Enum.each(fn pid ->
      Process.unlink(pid)
      Process.exit(pid, :kill)
    end)
  end

  defp normalize_headers(headers), do: Enum.map(headers, fn {name, value} -> {String.downcase(name), value} end)

  defp request_id(headers) do
    Enum.find_value(["x-request-id", "x-qdrant-request-id", "trace-id", "x-trace-id"], fn name ->
      case List.keyfind(headers, name, 0) do
        {^name, value} -> value
        nil -> nil
      end
    end)
  end

  defp decode_or_transport({Tesla.Middleware.JSON, :decode, _reason}), do: :decode
  defp decode_or_transport({:error, %JSON.DecodeError{}}), do: :decode
  defp decode_or_transport(%JSON.DecodeError{}), do: :decode
  defp decode_or_transport(_), do: :transport
end
