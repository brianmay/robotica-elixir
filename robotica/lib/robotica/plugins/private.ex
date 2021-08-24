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

  @spec check_type(map(), String.t()) :: {map(), boolean()}
  def check_type(command, type) do
    if command.type == type or command.type == nil do
      {%{command | type: type}, true}
    else
      Logger.info("Wrong type #{command.type}, expected #{type}")
      {command, false}
    end
  end
end
