exclude = if System.get_env("QDRANT_INTEGRATION") == "true", do: [], else: [:integration]
ExUnit.start(exclude: exclude)
