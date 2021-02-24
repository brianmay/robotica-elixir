defmodule RoboticaPlugins.Buttons.Music do
  @moduledoc """
  Music Buttons
  """
  use RoboticaPlugins.EventBus
  @behaviour RoboticaPlugins.Buttons

  alias RoboticaPlugins.Buttons.Config
  alias RoboticaPlugins.Buttons

  @type state :: String.t() | nil | :stop

  @spec get_topics(Config.t()) :: list({list(String.t()), atom(), atom()})
  def get_topics(%Config{} = config) do
    [
      {["state", config.location, config.device, "play_list"], :raw, :play_list}
    ]
  end

  @spec get_initial_state(Config.t()) :: state
  def get_initial_state(%Config{}) do
    nil
  end

  @spec process_message(Config.t(), atom(), any(), state) :: state
  def process_message(%Config{}, :play_list, "STOP", _) do
    :stop
  end

  def process_message(%Config{}, :play_list, data, _) do
    data
  end

  @spec get_display_state(Config.t(), state) :: Buttons.display_state()
  def get_display_state(%Config{action: _}, "ERROR"), do: :state_error
  def get_display_state(%Config{action: _}, nil), do: nil
  def get_display_state(%Config{action: "stop"}, :stop), do: :state_on
  def get_display_state(%Config{action: "play_red"}, "red"), do: :state_on
  def get_display_state(%Config{action: "play_green"}, "green"), do: :state_on
  def get_display_state(%Config{action: "play_blue"}, "blue"), do: :state_on
  def get_display_state(%Config{action: "play_wake_up"}, "wake_up"), do: :state_on
  def get_display_state(%Config{action: _}, _), do: :state_off

  @spec play(Config.t(), String.t()) :: list(RoboticaPlugins.Command.t())
  defp play(%Config{} = config, play_list) do
    [
      %RoboticaPlugins.Command{
        location: config.location,
        device: config.device,
        msg: %{
          "music" => %{"play_list" => play_list}
        }
      }
    ]
  end

  @spec stop(Config.t()) :: list(RoboticaPlugins.Command.t())
  defp stop(%Config{} = config) do
    [
      %RoboticaPlugins.Command{
        location: config.location,
        device: config.device,
        msg: %{
          "music" => %{
            "stop" => true
          }
        }
      }
    ]
  end

  @spec get_press_commands(Config.t(), state) :: list(RoboticaPlugins.Command.t())
  def get_press_commands(%Config{action: "play_red"} = config, _state),
    do: play(config, "red")

  def get_press_commands(%Config{action: "play_green"} = config, _state),
    do: play(config, "green")

  def get_press_commands(%Config{action: "play_blue"} = config, _state),
    do: play(config, "blue")

  def get_press_commands(%Config{action: "play_wake_up"} = config, _state),
    do: play(config, "wake_up")

  def get_press_commands(%Config{action: "stop"} = config, _state),
    do: stop(config)
end
