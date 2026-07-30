defmodule Qdrant.TypesTest do
  use ExUnit.Case, async: true

  @required_types [
    :result,
    :request_body,
    :request_options,
    :batch_request,
    :json_value,
    :health_body,
    :request_option,
    :extended_point_id,
    :point_ids,
    :point_id_list,
    :consistency,
    :ordering,
    :dense_vector,
    :sparse_vector,
    :multivector,
    :named_vector,
    :vector,
    :payload_selector,
    :with_payload_interface,
    :point,
    :score_threshold,
    :match_any,
    :match_except,
    :match,
    :hnsw_config,
    :quantization_config,
    :optimizers_config
  ]

  test "publishes the canonical shared type set" do
    assert {:ok, types} = Code.Typespec.fetch_types(Qdrant.Types)
    names = MapSet.new(types, fn {_kind, {name, _type, _args}} -> name end)

    assert MapSet.subset?(MapSet.new(@required_types), names)
  end

  test "canonical type ASTs retain corrected scalar, vector, selector, and enum shapes" do
    assert type_string(:extended_point_id) =~ "non_neg_integer() | String.t()"
    assert type_string(:point_ids) =~ "[extended_point_id()]"
    assert type_string(:dense_vector) =~ "[number()]"
    assert type_string(:sparse_vector) =~ "indices: [non_neg_integer()]"
    assert type_string(:sparse_vector) =~ "values: [number()]"
    assert type_string(:multivector) =~ "[dense_vector()]"
    assert type_string(:named_vector) =~ "name: String.t()"
    assert type_string(:payload_selector) =~ "include: [String.t()]"
    assert type_string(:payload_selector) =~ "exclude: [String.t()]"
    assert type_string(:score_threshold) =~ "number()"
    assert type_string(:match_any) =~ "any: [match_value()]"
    assert type_string(:match_except) =~ "except: [match_value()]"
    assert type_string(:point) =~ "optional(:payload)"
    assert type_string(:point) =~ "optional(:vector)"

    consistency = type_string(:consistency)
    assert consistency =~ ":majority"
    assert consistency =~ ":quorum"
    assert consistency =~ ":all"

    ordering = type_string(:ordering)
    assert ordering =~ ":weak"
    assert ordering =~ ":medium"
    assert ordering =~ ":strong"
  end

  defp type_string(name) do
    {:ok, types} = Code.Typespec.fetch_types(Qdrant.Types)
    {_kind, type} = Enum.find(types, fn {_kind, {type_name, _type, []}} -> type_name == name end)
    type |> Code.Typespec.type_to_quoted() |> Macro.to_string()
  end
end
