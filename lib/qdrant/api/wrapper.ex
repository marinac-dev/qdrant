defmodule Qdrant.Api.Wrapper do
  defmacro __using__(_opts) do
    quote do
      defp module_name(module) do
        case Application.get_env(:qdrant, :interface) do
          "rest" ->
            Module.concat(["Qdrant", "Api", "Http", module])

          "grpc" ->
            Module.concat(["Qdrant", "Api", "Grpc", module])

          _ ->
            raise """
            Invalid interface configuration for Qdrant.
            Use `rest` or `grpc` as interface.
            Please check docs for more information.
            """
        end
      end

      import(Qdrant.Api.Wrapper, only: [api_call: 3])
    end
  end

  @doc false
  defmacro api_call(module, fn_name, params) do
    quote do
      module_name(unquote(module)) |> apply(unquote(fn_name), unquote(params))
    end
  end
end
