defmodule Robotica.Client do
  @moduledoc """
  Robotica MQTT client
  """

  use GenServer
  @behaviour MqttPotion.Handler

  use EventBus.EventSource

  alias Robotica.Scheduler.Executor
  alias Robotica.Scheduler.Marks
  alias Robotica.Validation

  require Logger

  defmodule State do
    @moduledoc false
    @type t :: %__MODULE__{
            remote_scheduler: String.t() | nil
          }
    defstruct [:remote_scheduler]
  end

  def start_link(opts) do
    GenServer.start_link(__MODULE__, opts, name: __MODULE__)
  end

  @spec init(opts :: list) :: {:ok, State.t()}
  @impl GenServer
  def init(opts) do
    {:ok, %State{remote_scheduler: Keyword.fetch!(opts, :remote_scheduler)}}
  end

  @impl MqttPotion.Handler
  def handle_connect do
    GenServer.cast(__MODULE__, :connect)
  end

  @impl MqttPotion.Handler
  def handle_disconnect(_reason, _properties) do
    GenServer.cast(__MODULE__, :disconnect)
  end

  @impl MqttPotion.Handler
  def handle_message(topic, message) do
    GenServer.cast(__MODULE__, {:message, topic, message})
  end

  @impl MqttPotion.Handler
  def handle_puback(_ack) do
    :ok
  end

  @impl GenServer
  def handle_cast(:connect, state) do
    Logger.info("MQTT Connection has been established")
    Executor.publish_schedule(Executor)
    {:noreply, state}
  end

  def handle_cast(:disconnect, state) do
    Logger.warn("MQTT Connection has been dropped")
    {:noreply, state}
  end

  def handle_cast({:message, ["execute"], message}, state) do
    Logger.info("Received mqtt topic: #{message.topic} #{inspect(message)}")

    with {:ok, json} <- Poison.decode(message.payload),
         {:ok, tasks} <- Robotica.Config.validate_tasks(json) do
      Robotica.Executor.execute_tasks(tasks)
    else
      {:error, error} -> Logger.error("Invalid execute message received: #{inspect(error)}.")
    end

    {:noreply, state}
  end

  def handle_cast({:message, ["mark"], message}, state) do
    Logger.info("Received mqtt topic: #{message.topic} #{inspect(message)}")

    # We do not need to process mark unless we have a scheduler running
    if state.remote_scheduler == nil do
      with {:ok, json} <- Poison.decode(message.payload),
           {:ok, mark} <- Robotica.Config.validate_mark(json) do
        Marks.put_mark(Marks, mark)
        Executor.reload_marks(Executor)
      else
        {:error, error} -> Logger.error("Invalid mark message received: #{inspect(error)}.")
      end
    end

    {:noreply, state}
  end

  def handle_cast({:message, ["schedule", _], message}, state) do
    Logger.info("Received mqtt topic: #{message.topic} #{inspect(message)}")

    with {:ok, json} <- Poison.decode(message.payload),
         {:ok, steps} <- Validation.validate_scheduled_steps(json) do
      EventSource.notify %{topic: :schedule} do
        steps
      end
    else
      {:error, error} -> Logger.error("Invalid schedule message received: #{inspect(error)}.")
    end

    {:noreply, state}
  end

  def handle_cast({:message, topic, message}, state) do
    Logger.debug("handle message #{message.topic} #{inspect(message)}")
    :ok = RoboticaCommon.Subscriptions.message(topic, message.payload, message.retain)
    {:noreply, state}
  end
end
