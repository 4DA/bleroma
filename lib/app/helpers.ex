defmodule Bleroma.Helpers do
  require Hunter.Config
  require Hunter.Api
  
  alias Hunter.{Api.Request, Config}

  defp get_headers(nil), do: []

  defp get_headers(%Hunter.Client{bearer_token: token}) do
    [{:Authorization, "Bearer #{token}"}]
  end

  defp get_headers(headers) when is_list(headers), do: headers

  def request_dump!(url, to, method, payload, conn \\ nil) do
    headers = get_headers(conn)

    case Request.request(method, url, payload, headers, Hunter.Config.http_options()) do
      {:ok, body} ->
        body
      {:error, _} -> nil
    end
  end

  defp process_url(endpoint, %Hunter.Client{base_url: base_url}) do
    process_url(endpoint, base_url)
  end

  # defp process_url(endpoint, base_url) do
  #   base_url <> endpoint
  # end

  def status_dump(conn, id) do
    "/api/v1/statuses/#{id}"
    |> process_url(conn)
    |> request_dump!(:status, :get, [], conn)
  end

  def status_dump_str(base_url, id) do
    "#{base_url}/api/v1/statuses/#{id}"
    |> request_dump!(:status, :get, [])
  end
end
