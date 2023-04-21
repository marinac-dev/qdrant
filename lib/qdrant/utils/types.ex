defmodule Qdrant.Utils.Types do
  @moduledoc """
  This module contains basic types used in this Qdrant library
  """

  defmacro __using__(_) do
    quote do
      @type extended_point_id :: list(integer() | String.t())
      @type ordering :: :weak | :medium | :strong
    end
  end
end
