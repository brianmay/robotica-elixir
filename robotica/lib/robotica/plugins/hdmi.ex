defmodule Robotica.Plugins.HDMI do
  use GenServer
  use Robotica.Plugin
  require Logger

  defmodule Config do
    @type t :: %__MODULE__{}
    defstruct [:host, :destination]
  end

  ## Server Callbacks

  def init(plugin) do
    {:ok, plugin}
  end

  def config_schema do
    %{
      struct_type: Config,
      host: {:string, true},
      destination: {:integer, true}
    }
  end

  def handle_command(state, command) do
    IO.puts("#{state.config.host} #{command.source} #{state.config.destination}")
    Robotica.Devices.HDMI.switch(state.config.host, command.source, state.config.destination)
    {:noreply, state}
  end

  def handle_cast({:execute, %{hdmi: nil}}, state) do
    {:noreply, state}
  end

  def handle_cast({:execute, %{hdmi: hdmi}}, state) do
    IO.puts("#{state.config.host} #{hdmi.source} #{state.config.destination}")
    Robotica.Devices.HDMI.switch(state.config.host, hdmi.source, state.config.destination)
    {:noreply, state}
  end

  def handle_cast({:command, command}, state) do
    case Robotica.Config.validate_hdmi_command(command) do
      {:ok, command} -> handle_command(state, command)
      {:error, error} -> Logger.error("Invalid hdmi command received: #{inspect(error)}.")
    end
    {:noreply, state}
  end

  def handle_cast({:execute, action}, state) do
    case action.hdmi do
      nil ->
        nil

      command ->
        handle_command(state, command)
    end

    {:noreply, state}
  end
end
