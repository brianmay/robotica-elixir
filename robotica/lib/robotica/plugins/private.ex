defmodule Robotica.Plugins.Private do
  @moduledoc """
  Shared functions for plugins
  """

  require Logger

  @spec publish(String.t(), String.t(), map()) :: :ok
  def publish(location, device, command) do
    task = %RoboticaCommon.CommandTask{location: location, device: device, command: command}
    :ok = Robotica.Mqtt.publish_command_task(task)
  end
end
