defmodule Qdrant.Application do
  @moduledoc false

  use Application

  @impl true
  def start(_type, _args) do
    children = [{Finch, name: Qdrant.Finch}]
    Supervisor.start_link(children, strategy: :one_for_one, name: Qdrant.Supervisor)
  end
end
