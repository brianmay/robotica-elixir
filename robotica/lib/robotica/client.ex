defmodule Robotica.Client do
  @moduledoc """
  Robotica MQTT client
  """

  @behaviour MqttPotion.Handler

  use EventBus.EventSource

  alias Robotica.Scheduler.Executor

  require Logger

  defmodule State do
    @moduledoc false
    @type t :: %__MODULE__{
            remote_scheduler: String.t() | nil
          }
    defstruct [:remote_scheduler]
  end

  @impl MqttPotion.Handler
  def handle_connect do
    Logger.info("MQTT Connection has been established")
    Executor.publish_schedule(Executor)
    :ok
  end

  @impl MqttPotion.Handler
  def handle_disconnect(_reason, _properties) do
    Logger.warn("MQTT Connection has been dropped")
    :ok
  end

  @impl MqttPotion.Handler
  def handle_puback(_ack) do
    :ok
  end

  @impl MqttPotion.Handler
  def handle_message(_topic, message) do
    Logger.debug("handle message #{message.topic} #{inspect(message)}")
    :ok = MqttPotion.Multiplexer.message(message.topic, message.payload)
  end
end
