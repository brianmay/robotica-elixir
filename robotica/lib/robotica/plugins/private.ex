defmodule Robotica.Plugins.Private do
  @moduledoc """
  Shared functions for plugins
  """

  require Logger
  use RoboticaCommon.EventBus

  @spec publish(String.t(), String.t(), map()) :: :ok
  def publish(location, device, command) do
    task = %RoboticaCommon.CommandTask{location: location, device: device, command: command}
    :ok = RoboticaCommon.EventBus.notify(:command_task, task)
    :ok = RoboticaCommon.Mqtt.publish_command_task(task)
  end
end
