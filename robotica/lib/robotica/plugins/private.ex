defmodule Robotica.Plugins.Private do
  @moduledoc """
  Shared functions for plugins
  """

  require Logger

  @spec publish_state_raw(struct(), String.t(), String.t()) :: :ok
  def publish_state_raw(state, topic, value) do
    :ok = Robotica.Mqtt.publish_state_raw(state.location, state.device, value, topic: topic)
  end

  @spec publish_state_json(struct(), String.t(), map() | list()) :: :ok
  def publish_state_json(state, topic, value) do
    :ok = Robotica.Mqtt.publish_state_json(state.location, state.device, value, topic: topic)
  end

  @spec publish_command(String.t(), String.t(), map()) :: :ok
  def publish_command(location, device, command) do
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
