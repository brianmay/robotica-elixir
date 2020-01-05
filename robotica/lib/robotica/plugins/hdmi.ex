defmodule Robotica.Plugins.HDMI do
  use GenServer
  use Robotica.Plugin
  require Logger

  defmodule Config do
    @type t :: %__MODULE__{}
    defstruct [ :host, :destination ]
  end

  ## Server Callbacks

  def init(plugin) do
    {:ok, plugin}
  end

  def config_schema do
    %{
      struct_type: Config,
      host: {:string, true},
      destination: {:integer, true},
    }
  end

  def handle_cast({:execute, %{hdmi: nil}}, state) do
    {:noreply, state}
  end

  def handle_cast({:execute, %{hdmi: hdmi}}, state) do
    IO.puts("#{state.config.host} #{hdmi.source} #{state.config.destination}")
    Robotica.Devices.HDMI.switch(state.config.host, hdmi.source, state.config.destination)
    {:noreply, state}
  end

end
