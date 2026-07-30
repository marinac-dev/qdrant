defmodule Qdrant.Types do
  @moduledoc """
  Canonical shared types for Qdrant request and response values.

  Large request schemas evolve with Qdrant and are intentionally represented by
  `map()` in endpoint APIs rather than by incomplete closed maps.
  """

  @type extended_point_id :: non_neg_integer() | String.t()
  @type point_ids :: list(extended_point_id())
  @type point_id_list :: list(extended_point_id())

  @type consistency :: non_neg_integer() | :majority | :quorum | :all
  @type ordering :: :weak | :medium | :strong

  @type dense_vector :: list(number())
  @type sparse_vector :: %{
          required(:indices) => list(non_neg_integer()),
          required(:values) => list(number())
        }
  @type multivector :: list(dense_vector())
  @type unnamed_vector :: dense_vector() | sparse_vector() | multivector()
  @type named_vector :: %{
          required(:name) => String.t(),
          required(:vector) => unnamed_vector()
        }
  @type vector :: unnamed_vector() | named_vector()

  @type payload_selector ::
          %{required(:include) => list(String.t())}
          | %{required(:exclude) => list(String.t())}
  @type with_payload_interface :: boolean() | list(String.t()) | payload_selector()

  @type point :: %{
          required(:id) => extended_point_id(),
          optional(:vector) => vector(),
          optional(:payload) => map()
        }

  @type score_threshold :: number()
  @type match_value :: String.t() | number() | boolean()
  @type match_any :: %{required(:any) => list(match_value())}
  @type match_except :: %{required(:except) => list(match_value())}
  @type match :: %{
          optional(:value) => match_value(),
          optional(:text) => String.t(),
          optional(:any) => list(match_value()),
          optional(:except) => list(match_value())
        }

  @type hnsw_config :: %{
          optional(:m) => non_neg_integer(),
          optional(:ef_construct) => non_neg_integer(),
          optional(:full_scan_threshold) => non_neg_integer(),
          optional(:max_indexing_threads) => non_neg_integer(),
          optional(:on_disk) => boolean(),
          optional(:payload_m) => non_neg_integer()
        }

  @type quantization_config :: map()

  @type optimizers_config :: %{
          optional(:deleted_threshold) => number(),
          optional(:vacuum_min_vector_number) => non_neg_integer(),
          optional(:default_segment_number) => non_neg_integer(),
          optional(:max_segment_size) => non_neg_integer(),
          optional(:memmap_threshold) => non_neg_integer(),
          optional(:indexing_threshold) => non_neg_integer(),
          optional(:flush_interval_sec) => non_neg_integer(),
          optional(:max_optimization_threads) => pos_integer()
        }
end
