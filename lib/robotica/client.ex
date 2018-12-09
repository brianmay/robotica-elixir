defmodule Robotica.Client do
  require Logger

  defmodule State do
    @type t :: %__MODULE__{}
    defstruct []
  end

  @behaviour Tortoise.Handler

  @spec init(opts :: list) :: {:ok, State.t()}
  def init(_opts) do
    {:ok, %State{}}
  end

  def connection(:up, state) do
    Logger.info("Connection has been established")
    Robotica.Scheduler.Executor.publish_schedule(Robotica.Scheduler.Executor)
    {:ok, state}
  end

  def connection(:down, state) do
    Logger.warn("Connection has been dropped")
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
    Logger.info("#{Enum.join(topic, "/")} #{inspect(publish)}")

    with {:ok, message} <- Poison.decode(publish),
         {:ok, task} <- Robotica.Config.validate_task(message) do
      Robotica.Executor.execute(Robotica.Executor, task)
    else
      {:error, error} -> Logger.error("Invalid message received: #{error}.")
    end

    {:ok, state}
  end

  def handle_message(["request", _, "schedule"] = topic, publish, state) do
    Logger.info("#{Enum.join(topic, "/")} #{inspect(publish)}")
    Robotica.Scheduler.Executor.publish_schedule(Robotica.Scheduler.Executor)
    {:ok, state}
  end

  def handle_message(topic, publish, state) do
    IO.inspect(topic)
    Logger.info("Received unknown topic: #{Enum.join(topic, "/")} #{inspect(publish)}")
    {:ok, state}
  end

  def terminate(reason, _state) do
    Logger.warn("Client has been terminated with reason: #{inspect(reason)}")
    :ok
  end
end
