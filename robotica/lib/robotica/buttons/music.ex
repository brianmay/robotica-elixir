defmodule Robotica.Buttons.Music do
  @moduledoc """
  Music Buttons
  """
  use RoboticaCommon.EventBus
  @behaviour Robotica.Buttons

  alias Robotica.Buttons
  alias Robotica.Buttons.Config

  @type state :: String.t() | nil | :stop

  @spec get_topics(Config.t()) :: list({String.t(), atom(), atom()})
  def get_topics(%Config{} = config) do
    [
      {"state/#{config.location}/#{config.device}/play_list", :raw, :play_list}
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

  def get_display_state(%Config{action: "play", params: %{"play_list" => play_list}}, play_list),
    do: :state_on

  def get_display_state(%Config{action: _}, _), do: :state_off

  @spec play(Config.t(), String.t()) :: list(Robotica.Types.CommandTask.t())
  defp play(%Config{} = config, play_list) do
    [
      %Robotica.Types.CommandTask{
        topic: "command/#{config.location}/#{config.device}",
        payload_json: %{
          "type" => "audio",
          "music" => %{"play_list" => play_list}
        },
        qos: 1
      }
    ]
  end

  @spec stop(Config.t()) :: list(Robotica.Types.CommandTask.t())
  defp stop(%Config{} = config) do
    [
      %Robotica.Types.CommandTask{
        topic: "command/#{config.location}/#{config.device}",
        payload_json: %{
          "type" => "audio",
          "music" => %{
            "stop" => true
          }
        },
        qos: 1
      }
    ]
  end

  @spec get_press_commands(Config.t(), state) :: list(Robotica.Types.CommandTask.t())
  def get_press_commands(%Config{action: "play"} = config, _state),
    do: play(config, config.params["play_list"])

  def get_press_commands(%Config{action: "stop"} = config, _state),
    do: stop(config)
end
