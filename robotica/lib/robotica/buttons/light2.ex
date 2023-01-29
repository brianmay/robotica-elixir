defmodule Robotica.Buttons.Light2 do
  @moduledoc """
  LIFX Buttons
  """
  use RoboticaCommon.EventBus
  @behaviour Robotica.Buttons

  alias Robotica.Buttons
  alias Robotica.Buttons.Config

  @type state :: {String.t() | nil, map() | nil}

  @spec get_topics(Config.t()) :: list({String.t(), atom(), atom()})
  def get_topics(%Config{} = config) do
    [
      {"state/#{config.location}/#{config.device}/scene", :raw, :scene},
      {"state/#{config.location}/#{config.device}/power", :json, :power}
    ]
  end

  @spec process_message(Config.t(), atom(), any(), state) :: state
  def process_message(%Config{}, :scene, data, {_scene, power}) do
    {data, power}
  end

  def process_message(%Config{}, :power, data, {scene, _power}) do
    {scene, data}
  end

  @spec get_initial_state(Config.t()) :: state
  def get_initial_state(%Config{}) do
    {nil, nil}
  end

  @spec get_display_state(Config.t(), state) :: Buttons.display_state()
  def get_display_state(%Config{action: "turn_on"} = config, {scene, power}) do
    scene_selected = config.params["scene"] == scene

    case power do
      nil ->
        nil

      "offline" ->
        :state_hard_off

      "on" when scene_selected ->
        :state_on

      "off" when scene_selected ->
        :state_on

      "on" when not scene_selected ->
        :state_off

      "off" when not scene_selected ->
        :state_off

      _ ->
        nil
    end
  end

  def get_display_state(%Config{action: "turn_off"} = _config, {scene, power}) do
    scene_selected = "off" == scene

    case power do
      nil ->
        nil

      "offline" ->
        :state_hard_off

      "on" when scene_selected ->
        :state_on

      "off" when scene_selected ->
        :state_on

      "on" when not scene_selected ->
        :state_off

      "off" when not scene_selected ->
        :state_off

      _ ->
        nil
    end
  end

  def get_display_state(%Config{action: "toggle"} = config, {scene, power}) do
    scene_selected = config.params["scene"] == scene

    case power do
      nil ->
        nil

      "offline" ->
        :state_hard_off

      "on" when scene_selected ->
        :state_on

      "off" when scene_selected ->
        :state_on

      "on" when not scene_selected ->
        :state_off

      "off" when not scene_selected ->
        :state_off

      _ ->
        nil
    end
  end

  @spec turn_on(Config.t()) :: list(Robotica.Types.CommandTask.t())
  defp turn_on(%Config{} = config) do
    [
      %Robotica.Types.CommandTask{
        topic: "command/#{config.location}/#{config.device}",
        payload_json: %{
          "type" => "light2",
          "action" => "turn_on",
          "scene" => config.params["scene"]
        },
        qos: 1
      }
    ]
  end

  @spec turn_off(Config.t()) :: list(Robotica.Types.CommandTask.t())
  defp turn_off(%Config{} = config) do
    [
      %Robotica.Types.CommandTask{
        topic: "command/#{config.location}/#{config.device}",
        payload_json: %{
          "type" => "light2",
          "action" => "turn_off"
        },
        qos: 1
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
