defmodule Robotica.Executor do
  @moduledoc """
  Execute Robotica tasks in a pseudo synchronised manner
  """

  require Logger

  use RoboticaCommon.EventBus
  use GenServer
  use EventBus.EventSource

  defmodule State do
    @moduledoc false
    @type t :: %__MODULE__{}
    defstruct []
  end

  ## Client API

  @spec start_link(opts :: list) :: {:ok, pid} | {:error, String.t()}
  def start_link(opts) do
    GenServer.start_link(__MODULE__, :ok, opts)
  end

  @spec execute_tasks(tasks :: list(RoboticaCommon.Task.t())) :: :ok
  def execute_tasks(tasks) do
    GenServer.cast(Robotica.Executor, {:execute_tasks, tasks})
  end

  ## Server Callbacks

  @impl true
  def init(:ok) do
    Robotica.Subscriptions.subscribe(
      ["execute"],
      :execute,
      self(),
      :json,
      :no_resend
    )

    {:ok, %State{}}
  end

  @spec handle_execute_tasks(tasks :: list(RoboticaCommon.Task.t())) :: :ok
  defp handle_execute_tasks(tasks) do
    Enum.each(tasks, fn scheduled_task ->
      Enum.each(scheduled_task.locations, fn location ->
        Enum.each(scheduled_task.devices, fn device ->
          command = %RoboticaCommon.CommandTask{
            location: location,
            device: device,
            command: scheduled_task.command
          }

          Robotica.PluginRegistry.execute_command_task(command, remote: false)
        end)
      end)
    end)

    # Hack: Wait for messages to complete
    has_msg? =
      Enum.any?(tasks, fn scheduled_task ->
        correct_type =
          scheduled_task.command["type"] == "audio" or scheduled_task.command["type"] == nil

        correct_type and scheduled_task.command["message"] != nil
      end)

    if has_msg? do
      Process.sleep(20_000)
    end

    :ok
  end

  @impl true
  def handle_cast({:mqtt, _, :execute, json}, state) do
    case Robotica.Config.validate_tasks(json) do
      {:ok, tasks} -> :ok = handle_execute_tasks(tasks)
      {:error, reason} -> Logger.error("Invalid execute message received: #{reason}")
    end

    {:noreply, state}
  end

  def handle_cast({:execute_tasks, tasks}, state) do
    :ok = handle_execute_tasks(tasks)
    {:noreply, state}
  end
end
