defmodule Robotica.Buttons.HDMI do
  @moduledoc """
  HDMI Buttons
  """
  use RoboticaCommon.EventBus
  @behaviour Robotica.Buttons

  alias Robotica.Buttons
  alias Robotica.Buttons.Config

  @spec get_topic_for_output(integer()) :: String.t()
  defp get_topic_for_output(n), do: "output#{n}"

  @type state :: integer() | String.t() | nil
  @spec get_topics(Config.t()) :: list({String.t(), atom(), atom()})
  def get_topics(%Config{} = config) do
    topic = get_topic_for_output(config.params["output"])

    [
      {"state/#{config.location}/#{config.device}/#{topic}", :raw, :output}
    ]
  end

  @spec get_initial_state(Config.t()) :: state
  def get_initial_state(%Config{}) do
    nil
  end

  @spec process_message(Config.t(), atom(), any(), state) :: state
  def process_message(%Config{}, :output, data, _) do
    case Integer.parse(data) do
      {value, ""} -> value
      _ -> data
    end
  end

  @spec get_display_state(Config.t(), state) :: Buttons.display_state()
  def get_display_state(%Config{action: _}, "HARD_OFF"), do: :state_hard_off
  def get_display_state(%Config{action: _}, "ERROR"), do: :state_error
  def get_display_state(%Config{action: _}, nil), do: nil

  def get_display_state(%Config{action: "switch", params: %{"input" => n}}, n), do: :state_on
  def get_display_state(%Config{action: _}, _), do: :state_off

  @spec switch(Config.t()) :: list(Robotica.Types.CommandTask.t())
  defp switch(%Config{} = config) do
    [
      %Robotica.Types.CommandTask{
        topic: "command/#{config.location}/#{config.device}",
        payload_json: %{
          "type" => "hdmi",
          "input" => config.params["input"],
          "output" => config.params["output"]
        },
        qos: 1
      }
    ]
  end

  @spec get_press_commands(Config.t(), state) :: list(Robotica.Types.CommandTask.t())
  def get_press_commands(%Config{action: "switch"} = config, _state), do: switch(config)
end
