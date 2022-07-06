defmodule Robotica.Buttons.Light do
  @moduledoc """
  LIFX Buttons
  """
  use RoboticaCommon.EventBus
  @behaviour Robotica.Buttons

  alias Robotica.Buttons
  alias Robotica.Buttons.Config

  @type state :: {String.t() | nil, list(String.t()) | nil, list(integer) | nil}

  @spec get_topics(Config.t()) :: list({list(String.t()), atom(), atom()})
  def get_topics(%Config{} = config) do
    [
      {["state", config.location, config.device, "power"], :raw, :power},
      {["state", config.location, config.device, "scenes"], :json, :scenes},
      {["state", config.location, config.device, "priorities"], :json, :priorities}
    ]
  end

  @spec process_message(Config.t(), atom(), any(), state) :: state
  def process_message(%Config{}, :power, data, {_power, scenes, priorities}) do
    {data, scenes, priorities}
  end

  def process_message(%Config{}, :scenes, data, {power, _scenes, priorities}) do
    {power, data, priorities}
  end

  def process_message(%Config{}, :priorities, data, {power, scenes, _priorities}) do
    {power, scenes, data}
  end

  @spec get_initial_state(Config.t()) :: state
  def get_initial_state(%Config{}) do
    {nil, nil, nil}
  end

  @spec has_scene?(list(String.t()) | nil, String.t()) :: boolean() | nil
  def has_scene?(scenes, scene) do
    if scenes == nil do
      nil
    else
      Enum.member?(scenes, scene)
    end
  end

  @spec has_priority?(list(integer) | nil, integer()) :: boolean() | nil
  def has_priority?(priorities, priority) do
    if priorities == nil do
      nil
    else
      Enum.member?(priorities, priority)
    end
  end

  # @spec has_one_of_scenes?(list(String.t()) | nil, list(String.t())) :: boolean() | nil
  # def has_one_of_scenes?(scenes, required_scenes) do
  #   if scenes == nil do
  #     nil
  #   else
  #     Enum.any?(required_scenes, fn scene -> Enum.member?(scenes, scene) end)
  #   end
  # end

  # @spec has_any_scenes?(list(String.t()) | nil) :: boolean() | nil
  # def has_any_scenes?(scenes) do
  #   if scenes == nil do
  #     nil
  #   else
  #     scenes == []
  #   end
  # end

  @spec get_display_state(Config.t(), state) :: Buttons.display_state()
  def get_display_state(%Config{action: "turn_on"} = config, {power, scenes, _}) do
    has_scene? = has_scene?(scenes, config.params["scene"])

    case {power, scenes, has_scene?} do
      {"HARD_OFF", _, _} -> :state_hard_off
      {_, _, nil} -> nil
      {_, _, true} -> :state_on
      {_, _, false} -> :state_off
    end
  end

  def get_display_state(%Config{action: "turn_off"} = config, {power, _scenes, priorities}) do
    has_priority? = has_priority?(priorities, config.params["priority"])

    case {power, priorities, has_priority?} do
      {"HARD_OFF", _, _} -> :state_hard_off
      {"ON", [], _} -> :state_off
      {"OFF", [], _} -> :state_on
      {_, _, nil} -> nil
      {_, _, true} -> :state_off
      {_, _, false} -> :state_on
    end
  end

  def get_display_state(%Config{action: "toggle"} = config, {power, scenes, _priorities}) do
    has_scene? = has_scene?(scenes, config.params["scene"])

    case {power, scenes, has_scene?} do
      {"HARD_OFF", _, _} -> :state_hard_off
      {_, _, nil} -> nil
      {_, _, true} -> :state_on
      {_, _, false} -> :state_off
    end
  end

  @spec turn_on(Config.t()) :: list(Robotica.Types.CommandTask.t())
  defp turn_on(%Config{} = config) do
    [
      %Robotica.Types.CommandTask{
        location: config.location,
        device: config.device,
        command: %{
          "scene" => config.params["scene"],
          "priority" => config.params["priority"]
        }
      }
    ]
  end

  @spec turn_off(Config.t()) :: list(Robotica.Types.CommandTask.t())
  defp turn_off(%Config{} = config) do
    [
      %Robotica.Types.CommandTask{
        location: config.location,
        device: config.device,
        command: %{
          "action" => "turn_off",
          "scene" => config.params["scene"],
          "priority" => config.params["priority"]
        }
      }
    ]
  end

  @spec get_press_commands(Config.t(), state) :: list(Robotica.Types.CommandTask.t())
  def get_press_commands(%Config{action: "turn_on"} = config, _state), do: turn_on(config)
  def get_press_commands(%Config{action: "turn_off"} = config, _state), do: turn_off(config)

  def get_press_commands(%Config{action: "toggle"} = config, state) do
    case get_display_state(config, state) do
      :state_on -> turn_off(config)
      _ -> turn_on(config)
    end
  end
end
