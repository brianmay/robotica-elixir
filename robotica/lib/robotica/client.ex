defmodule Robotica.Client do
  @moduledoc """
  Robotica MQTT client
  """

  use Tortoise.Handler
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

  @spec init(opts :: list) :: {:ok, State.t()}
  def init(opts) do
    {:ok, %State{remote_scheduler: Keyword.fetch!(opts, :remote_scheduler)}}
  end

  def connection(:up, state) do
    Logger.info("Connection has been established")
    Executor.publish_schedule(Executor)
    {:ok, state}
  end

  def connection(:down, state) do
    Logger.warn("Connection has been dropped")
    {:ok, state}
  end

  def connection(:terminating, state) do
    Logger.warn("Connection is terminating")
    {:ok, state}
  end

  def connection(:terminated, state) do
    Logger.warn("Connection has been terminated")
    {:ok, state}
  end

  def subscription(:up, topic, state) do
    Logger.info("Subscribed to #{topic}")
    {:ok, state}
  end

  def subscription({:warn, [requested: req, accepted: qos]}, topic, state) do
    Logger.warn("Subscribed to #{topic}; requested #{req} but got accepted with QoS #{qos}")
    {:ok, state}
  end

  def subscription({:error, reason}, topic, state) do
    Logger.error("Error subscribing to #{topic}; #{inspect(reason)}")
    {:ok, state}
  end

  def subscription(:down, topic, state) do
    Logger.info("Unsubscribed from #{topic}")
    {:ok, state}
  end

  def handle_message(["execute"] = topic, publish, state) do
    Logger.info("Received mqtt topic: #{Enum.join(topic, "/")} #{inspect(publish)}")

    with {:ok, message} <- Poison.decode(publish),
         {:ok, tasks} <- Robotica.Config.validate_tasks(message) do
      Robotica.Executor.execute_tasks(tasks)
    else
      {:error, error} -> Logger.error("Invalid execute message received: #{inspect(error)}.")
    end

    {:ok, state}
  end

  def handle_message(["mark"] = topic, publish, state) do
    Logger.info("Received mqtt topic: #{Enum.join(topic, "/")} #{inspect(publish)}")

    # We do not need to process mark unless we have a scheduler running
    if state.remote_scheduler == nil do
      with {:ok, message} <- Poison.decode(publish),
           {:ok, mark} <- Robotica.Config.validate_mark(message) do
        Marks.put_mark(Marks, mark)
        Executor.reload_marks(Executor)
      else
        {:error, error} -> Logger.error("Invalid mark message received: #{inspect(error)}.")
      end
    end

    {:ok, state}
  end

  def handle_message(["schedule", _] = topic, publish, state) do
    Logger.info("Received mqtt topic: #{Enum.join(topic, "/")} #{inspect(publish)}")

    with {:ok, message} <- Poison.decode(publish),
         {:ok, steps} <- Validation.validate_scheduled_steps(message) do
      EventSource.notify %{topic: :schedule} do
        steps
      end
    else
      {:error, error} -> Logger.error("Invalid schedule message received: #{inspect(error)}.")
    end

    {:ok, state}
  end

  def handle_message(topic, publish, state) do
    Logger.debug("handle message #{inspect(topic)} #{inspect(publish)}")
    :ok = RoboticaCommon.Subscriptions.message(topic, publish)
    {:ok, state}
  end

  def terminate(reason, _state) do
    Logger.warn("Client has been terminated with reason: #{inspect(reason)}")
    :ok
  end
end
