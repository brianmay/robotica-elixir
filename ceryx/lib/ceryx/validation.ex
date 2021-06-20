defmodule Ceryx.Validation do
  @moduledoc """
  Json validation functions for ceryx
  """

  alias RoboticaCommon.Schema
  alias RoboticaCommon.Validation

  def validate_task(%{} = data) do
    Validation.validate_schema(data, Schema.task_schema())
  end

  def validate_mark(%{} = data) do
    Validation.validate_schema(data, Schema.mark_schema())
  end

  def validate_scheduled_steps(data) do
    Validation.validate_schema(data, {:list, Schema.scheduled_step_schema()})
  end
end
