defmodule Qdrant.Utils.Types do
  @moduledoc """
  This module contains basic types (primitives of sort) used in this Qdrant library.
  """

  defmacro __using__(_) do
    quote do
      # * Collection types
      @type extended_point_id :: list(non_neg_integer() | String.t())
      @type ordering :: :weak | :medium | :strong

      @type hnsw_config :: %{
              m: non_neg_integer() | nil,
              ef_construct: non_neg_integer() | nil,
              full_scan_threshold: non_neg_integer() | nil,
              max_indexing_threads: non_neg_integer() | nil,
              on_disk: boolean() | nil,
              payload_m: non_neg_integer() | nil
            }

      @type quantization_config :: %{
              scalar: %{
                type: String.t(),
                quantile: float(),
                always_ram: boolean()
              }
            }

      @type optimizers_config :: %{
              deleted_threshold: float() | nil,
              vacuum_min_vector_number: non_neg_integer() | nil,
              default_segment_number: non_neg_integer() | nil,
              max_segment_size: non_neg_integer() | nil,
              memmap_threshold: non_neg_integer() | nil,
              indexing_threshold: non_neg_integer() | nil,
              flush_interval_sec: non_neg_integer() | nil,
              max_optimization_threads: pos_integer() | nil
            }

      # * Search types
      @type consistency :: non_neg_integer() | :majority | :quorum | :all
      @type vector :: list(float()) | %{name: String.t(), vector: list(float())}
      @type point :: %{id: non_neg_integer() | String.t(), vector: list(float()), payload: map()}
      @type with_payload_interface :: boolean() | list(String.t()) | %{include: String.t(), exclude: String.t()}
    end
  end
end
