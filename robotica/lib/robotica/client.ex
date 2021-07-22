defmodule Robotica.Client do
  @moduledoc """
  Robotica MQTT client
  """

  @behaviour MqttPotion.Handler

  use EventBus.EventSource

  alias Robotica.Scheduler.Executor
  alias Robotica.Validation

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
  def handle_message(["schedule", _], message) do
    Logger.info("Received mqtt topic: #{message.topic} #{inspect(message)}")

    with {:ok, json} <- Jason.decode(message.payload),
         {:ok, steps} <- Validation.validate_scheduled_steps(json) do
      EventSource.notify %{topic: :schedule} do
        steps
      end
    else
      {:error, error} -> Logger.error("Invalid schedule message received: #{inspect(error)}.")
    end
  end

  @impl MqttPotion.Handler
  def handle_message(topic, message) do
    Logger.debug("handle message #{message.topic} #{inspect(message)}")
    :ok = Robotica.Subscriptions.message(topic, message.payload, message.retain)
  end
end
