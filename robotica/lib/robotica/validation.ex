defmodule Robotica.Validation do
  @moduledoc """
  Robotica specific json validation stuff
  """

  alias RoboticaCommon.Schema
  alias RoboticaCommon.Validation

  defp module_to_schema(module), do: {:ok, apply(module, :config_schema, [])}

  def validate_plugin_config(raw_data, data) do
    with {:ok, raw_config} <- Map.fetch(raw_data, "config"),
         {:ok, config_schema} <- module_to_schema(data.module),
         {:ok, config} <- Validation.validate_schema(raw_config, config_schema) do
      {:ok, Map.put(data, :config, config)}
    else
      {:error, err} -> {:error, err}
      :error -> {:error, "Cannot parse module config"}
    end
  end

  def validate_mark(%{} = data) do
    Validation.validate_schema(data, Schema.mark_schema())
  end
end
