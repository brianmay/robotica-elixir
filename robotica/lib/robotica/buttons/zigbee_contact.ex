defmodule Robotica.Buttons.ZigbeeContact do
  @moduledoc """
  Switch Buttons
  """
  use RoboticaCommon.EventBus
  @behaviour Robotica.Buttons

  alias Robotica.Buttons
  alias Robotica.Buttons.Config

  @type state :: bool | nil

  @spec get_topics(Config.t()) :: list({list(String.t()), atom(), atom()})
  def get_topics(%Config{} = config) do
    [
      {["zigbee2mqtt", config.location, config.device], :json, :power}
    ]
  end

  @spec get_initial_state(Config.t()) :: state
  def get_initial_state(%Config{}) do
    nil
  end

  @spec process_message(Config.t(), atom(), any(), state) :: state
  def process_message(%Config{}, :power, data, _) do
    data["contact"]
  end

  @spec get_display_state(Config.t(), state) :: Buttons.display_state()
  def get_display_state(_, true), do: :state_off
  def get_display_state(_, false), do: :state_on
  def get_display_state(%Config{action: _}, _), do: nil

  @spec get_press_commands(Config.t(), state) :: list(Robotica.Types.CommandTask.t())
  def get_press_commands(_, _state),
    do: []
end
