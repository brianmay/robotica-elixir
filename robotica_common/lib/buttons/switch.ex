defmodule RoboticaPlugins.Buttons.Switch do
  @moduledoc """
  Switch Buttons
  """
  use RoboticaPlugins.EventBus
  @behaviour RoboticaPlugins.Buttons

  alias RoboticaPlugins.Buttons.Config
  alias RoboticaPlugins.Buttons

  @type state :: String.t() | nil

  @spec get_topics(Config.t()) :: list({list(String.t()), atom(), atom()})
  def get_topics(%Config{} = config) do
    [
      {["state", config.location, config.device, "power"], :raw, :power}
    ]
  end

  @spec get_initial_state(Config.t()) :: state
  def get_initial_state(%Config{}) do
    nil
  end

  @spec process_message(Config.t(), atom(), any(), state) :: state
  def process_message(%Config{}, :power, data, _) do
    data
  end

  @spec get_display_state(Config.t(), state) :: Buttons.display_state()
  def get_display_state(%Config{action: _}, "ERROR"), do: :state_error
  def get_display_state(%Config{action: _}, "HARD_OFF"), do: :state_hard_off
  def get_display_state(%Config{action: _}, nil), do: nil
  def get_display_state(%Config{action: "turn_on"}, "ON"), do: :state_on
  def get_display_state(%Config{action: "turn_on"}, "OFF"), do: :state_off
  def get_display_state(%Config{action: "toggle"}, "ON"), do: :state_on
  def get_display_state(%Config{action: "toggle"}, "OFF"), do: :state_off
  def get_display_state(%Config{action: "turn_off"}, "ON"), do: :state_off
  def get_display_state(%Config{action: "turn_off"}, "OFF"), do: :state_on
  def get_display_state(%Config{action: "input_4"}, "4"), do: :state_on
  def get_display_state(%Config{action: _}, _), do: nil

  @spec turn_on(Config.t()) :: list(RoboticaPlugins.Command.t())
  defp turn_on(%Config{} = config) do
    [
      %RoboticaPlugins.CommandTask{
        location: config.location,
        device: config.device,
        command: %{
          "action" => "turn_on"
        }
      }
    ]
  end

  @spec turn_off(Config.t()) :: list(RoboticaPlugins.Command.t())
  defp turn_off(%Config{} = config) do
    [
      %RoboticaPlugins.CommandTask{
        location: config.location,
        device: config.device,
        command: %{
          "action" => "turn_off"
        }
      }
    ]
  end

  @spec get_press_commands(Config.t(), state) :: list(RoboticaPlugins.Command.t())
  def get_press_commands(%Config{action: "turn_on"} = config, _state),
    do: turn_on(config)

  def get_press_commands(%Config{action: "turn_off"} = config, _state),
    do: turn_off(config)

  def get_press_commands(%Config{action: "toggle"} = config, "OFF"),
    do: turn_on(config)

  def get_press_commands(%Config{action: "toggle"} = config, "ON"),
    do: turn_off(config)

  def get_press_commands(%Config{action: "toggle"} = config, state) do
    case get_display_state(config, state) do
      :state_on -> turn_off(config)
      _ -> turn_on(config)
    end
  end
end
