defmodule RoboticaPlugins.Buttons.Light do
  @doc """
  Implement Buttons for Lights
  """
  use RoboticaPlugins.EventBus
  @behaviour RoboticaPlugins.Buttons

  alias RoboticaPlugins.Buttons.Config
  alias RoboticaPlugins.Buttons

  @type state :: {String.t() | nil, list(String.t()) | nil, list(integer) | nil}

  @spec get_topics(Config.t()) :: list({list(String.t()), atom(), {atom(), atom()}})
  def get_topics(%Config{} = config) do
    [
      {["state", config.location, config.device, "power"], :raw, {config.id, :power}},
      {["state", config.location, config.device, "tasks"], :json, {config.id, :tasks}},
      {["state", config.location, config.device, "priorities"], :json, {config.id, :priorities}}
    ]
  end

  @spec process_message(Config.t(), atom(), any(), state) :: state
  def process_message(%Config{}, :power, data, {_power, tasks, priorities}) do
    {data, tasks, priorities}
  end

  def process_message(%Config{}, :tasks, data, {power, _tasks, priorities}) do
    {power, data, priorities}
  end

  def process_message(%Config{}, :priorities, data, {power, tasks, _priorities}) do
    {power, tasks, data}
  end

  @spec get_initial_state(Config.t()) :: state
  def get_initial_state(%Config{}) do
    {nil, nil, nil}
  end

  @spec has_task?(list(String.t()) | nil, String.t()) :: boolean() | nil
  def has_task?(tasks, task) do
    if tasks == nil do
      nil
    else
      Enum.member?(tasks, task)
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

  # @spec has_one_of_tasks?(list(String.t()) | nil, list(String.t())) :: boolean() | nil
  # def has_one_of_tasks?(tasks, required_tasks) do
  #   if tasks == nil do
  #     nil
  #   else
  #     Enum.any?(required_tasks, fn task -> Enum.member?(tasks, task) end)
  #   end
  # end

  # @spec has_any_tasks?(list(String.t()) | nil) :: boolean() | nil
  # def has_any_tasks?(tasks) do
  #   if tasks == nil do
  #     nil
  #   else
  #     tasks == []
  #   end
  # end

  @spec get_display_state(Config.t(), state) :: Buttons.display_state()
  def get_display_state(%Config{action: "turn_on"}, {power, tasks, _}) do
    has_default? = has_task?(tasks, "default")

    case {power, has_default?} do
      {"HARD_OFF", _} -> :state_hard_off
      {_, nil} -> nil
      {_, true} -> :state_on
      {_, false} -> :state_off
    end
  end

  def get_display_state(%Config{action: "turn_off"}, {power, _tasks, priorities}) do
    has_priority? = has_priority?(priorities, 100)

    case {power, has_priority?} do
      {"HARD_OFF", _} -> :state_hard_off
      {_, nil} -> nil
      {_, true} -> :state_off
      {_, false} -> :state_on
    end
  end

  def get_display_state(%Config{action: "dim"}, {power, tasks, _priorities}) do
    has_dim? = has_task?(tasks, "dim")

    case {power, has_dim?} do
      {"HARD_OFF", _} -> :state_hard_off
      {_, nil} -> nil
      {_, true} -> :state_on
      {_, false} -> :state_off
    end
  end

  def get_display_state(%Config{action: "rainbow"}, {power, tasks, _priorities}) do
    has_dim? = has_task?(tasks, "rainbow")

    case {power, has_dim?} do
      {"HARD_OFF", _} -> :state_hard_off
      {_, nil} -> nil
      {_, true} -> :state_on
      {_, false} -> :state_off
    end
  end

  def get_display_state(%Config{action: "night_1"}, {power, tasks, _priorities}) do
    has_dim? = has_task?(tasks, "night_1")

    case {power, has_dim?} do
      {"HARD_OFF", _} -> :state_hard_off
      {_, nil} -> nil
      {_, true} -> :state_on
      {_, false} -> :state_off
    end
  end

  def get_display_state(%Config{action: "night_2"}, {power, tasks, _priorities}) do
    has_dim? = has_task?(tasks, "night_2")

    case {power, has_dim?} do
      {"HARD_OFF", _} -> :state_hard_off
      {_, nil} -> nil
      {_, true} -> :state_on
      {_, false} -> :state_off
    end
  end

  def get_display_state(%Config{action: "night_off"}, {power, _tasks, priorities}) do
    has_priority? = has_priority?(priorities, 0)

    case {power, has_priority?} do
      {"HARD_OFF", _} -> :state_hard_off
      {_, nil} -> nil
      {_, true} -> :state_off
      {_, false} -> :state_on
    end
  end

  def get_display_state(%Config{action: "toggle"}, {power, tasks, _priorities}) do
    has_default? = has_task?(tasks, "default")

    case {power, has_default?} do
      {"HARD_OFF", _} -> :state_hard_off
      {_, nil} -> nil
      {_, true} -> :state_on
      {_, false} -> :state_off
    end
  end

  @spec turn_on(Config.t()) :: list(RoboticaPlugins.Command.t())
  defp turn_on(%Config{} = config) do
    [
      %RoboticaPlugins.Command{
        locations: [config.location],
        devices: [config.device],
        msg: %{
          action: "turn_on",
          task: "default",
          color: %{saturation: 0, hue: 0, brightness: 100, kelvin: 3500}
        }
      }
    ]
  end

  @spec turn_off(Config.t()) :: list(RoboticaPlugins.Command.t())
  defp turn_off(%Config{} = config) do
    [
      %RoboticaPlugins.Command{
        locations: [config.location],
        devices: [config.device],
        msg: %{
          task: "default",
          action: "turn_off"
        }
      }
    ]
  end

  @spec dim(Config.t()) :: list(RoboticaPlugins.Command.t())
  defp dim(%Config{} = config) do
    [
      %RoboticaPlugins.Command{
        locations: [config.location],
        devices: [config.device],
        msg: %{
          action: "turn_on",
          task: "dim",
          color: %{saturation: 0, hue: 0, brightness: 10, kelvin: 3500}
        }
      }
    ]
  end

  @spec rainbow(Config.t()) :: list(RoboticaPlugins.Command.t())
  defp rainbow(%Config{} = config) do
    [
      %RoboticaPlugins.Command{
        locations: [config.location],
        devices: [config.device],
        msg: %{
          action: "animate",
          task: "rainbow",
          animation: %{
            frames: [
              %{
                sleep: 500,
                repeat: 12,
                color: %{hue: "{frame}*30", saturation: 100, brightness: 100, kelvin: 3500},
                colors: [
                  %{
                    count: 32,
                    colors: [
                      %{
                        hue: "{light}*30+{frame}*30",
                        saturation: 100,
                        brightness: 100,
                        kelvin: 3500
                      }
                    ]
                  }
                ]
              }
            ]
          }
        }
      }
    ]
  end

  @spec night_1(Config.t()) :: list(RoboticaPlugins.Command.t())
  defp night_1(%Config{} = config) do
    [
      %RoboticaPlugins.Command{
        locations: [config.location],
        devices: [config.device],
        msg: %{
          stop_priorities: [100],
          action: "turn_on",
          task: "night_1",
          priority: 0,
          color: %{hue: 57, saturation: 100, brightness: 6, kelvin: 3500}
        }
      }
    ]
  end

  @spec night_2(Config.t()) :: list(RoboticaPlugins.Command.t())
  defp night_2(%Config{} = config) do
    [
      %RoboticaPlugins.Command{
        locations: [config.location],
        devices: [config.device],
        msg: %{
          stop_priorities: [100],
          action: "turn_on",
          task: "night_2",
          priority: 0,
          color: %{hue: 64, saturation: 100, brightness: 6, kelvin: 3500}
        }
      }
    ]
  end

  @spec night_off(Config.t()) :: list(RoboticaPlugins.Command.t())
  defp night_off(%Config{} = config) do
    [
      %RoboticaPlugins.Command{
        locations: [config.location],
        devices: [config.device],
        msg: %{
          stop_priorities: [100],
          task: "default",
          priority: 0,
          action: "turn_off"
        }
      }
    ]
  end

  @spec get_press_commands(Config.t(), state) :: list(RoboticaPlugins.Command.t())
  def get_press_commands(%Config{action: "turn_on"} = config, _state), do: turn_on(config)
  def get_press_commands(%Config{action: "turn_off"} = config, _state), do: turn_off(config)
  def get_press_commands(%Config{action: "dim"} = config, _state), do: dim(config)
  def get_press_commands(%Config{action: "rainbow"} = config, _state), do: rainbow(config)
  def get_press_commands(%Config{action: "night_1"} = config, _state), do: night_1(config)
  def get_press_commands(%Config{action: "night_2"} = config, _state), do: night_2(config)
  def get_press_commands(%Config{action: "night_off"} = config, _state), do: night_off(config)

  def get_press_commands(%Config{action: "toggle"} = config, state) do
    case get_display_state(config, state) do
      :state_on -> turn_off(config)
      _ -> turn_on(config)
    end
  end
end
