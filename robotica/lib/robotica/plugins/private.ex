defmodule Robotica.Plugins.Private do
  @moduledoc """
  Shared functions for plugins
  """

  require Logger
  use RoboticaPlugins.EventBus

  @spec publish(String.t(), String.t(), map()) :: :ok
  def publish(location, device, command) do
    task = %RoboticaPlugins.CommandTask{location: location, device: device, command: command}
    :ok = RoboticaPlugins.EventBus.notify(:command_task, task)

    case RoboticaPlugins.Mqtt.publish_command_task(task) do
      :ok -> nil
      {:error, _} -> Logger.debug("Cannot send outgoing command task #{inspect(task)}.")
    end

    :ok
  end
end
