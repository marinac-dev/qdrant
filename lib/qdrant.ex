defmodule Qdrant do
  @moduledoc """
  Documentation for Qdrant.
  """

  use Application

  def start(_type, _args) do
    import Supervisor.Spec, warn: false

    children = [
    ]

    opts = [strategy: :one_for_one, name: Qdrant.Supervisor]
    Supervisor.start_link(children, opts)
  end
end
