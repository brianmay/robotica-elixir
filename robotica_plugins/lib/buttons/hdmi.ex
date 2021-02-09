defmodule RoboticaPlugins.Buttons.HDMI do
  @doc """
  Implement Buttons for Lights
  """
  use RoboticaPlugins.EventBus
  @behaviour RoboticaPlugins.Buttons

  alias RoboticaPlugins.Buttons.Config
  alias RoboticaPlugins.Buttons

  @type state :: String.t() | nil

  @spec get_topics(Config.t()) :: list({list(String.t()), atom(), {atom(), atom()}})
  def get_topics(%Config{} = config) do
    [
      {["state", config.location, config.device, "input"], :raw, {config.id, :input}}
    ]
  end

  @spec get_initial_state(Config.t()) :: state
  def get_initial_state(%Config{}) do
    nil
  end

  @spec process_message(Config.t(), atom(), any(), state) :: state
  def process_message(%Config{}, :input, "", _) do
    nil
  end

  def process_message(%Config{}, :input, data, _) do
    data
  end

  @spec get_display_state(Config.t(), state) :: Buttons.display_state()
  def get_display_state(%Config{action: _}, "ERROR"), do: :state_error
  def get_display_state(%Config{action: _}, nil), do: nil
  def get_display_state(%Config{action: "input_1"}, "1"), do: :state_on
  def get_display_state(%Config{action: "input_2"}, "2"), do: :state_on
  def get_display_state(%Config{action: "input_3"}, "3"), do: :state_on
  def get_display_state(%Config{action: "input_4"}, "4"), do: :state_on
  def get_display_state(%Config{action: _}, _), do: :state_off

  @spec input(Config.t(), integer) :: list(RoboticaPlugins.Command.t())
  defp input(%Config{} = config, source) do
    [
      %RoboticaPlugins.Command{
        locations: [config.location],
        devices: [config.device],
        msg: %{
          source: source
        }
      }
    ]
  end

  @spec get_press_commands(Config.t(), state) :: list(RoboticaPlugins.Command.t())
  def get_press_commands(%Config{action: "input_1"} = config, _state),
    do: input(config, 1)

  def get_press_commands(%Config{action: "input_2"} = config, _state),
    do: input(config, 2)

  def get_press_commands(%Config{action: "input_3"} = config, _state),
    do: input(config, 3)

  def get_press_commands(%Config{action: "input_4"} = config, _state),
    do: input(config, 4)
end
