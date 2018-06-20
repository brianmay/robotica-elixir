defmodule Robotica.Plugins.Logging do
  use GenServer
  require Logger

  defmodule State do
    @type t :: %__MODULE__{
            location: String.t()
          }
    @enforce_keys [:location]
    defstruct location: nil
  end

  ## Client API

  @spec start_link(config: State.t()) :: {:ok, pid} | {:error, String.t()}
  def start_link(config) do
    Logger.info("Robotica.Plugins.Logging: Starting....")

    with {:ok, pid} <- GenServer.start_link(__MODULE__, config, []) do
      Logger.info("Robotica.Plugins.Logging: Registering....")
      Robotica.Registry.add(Robotica.Registry, config.location, pid)
      Logger.info("Robotica.Plugins.Logging: Started.")
      {:ok, pid}
    else
      err ->
        Logger.error("Robotica.Plugins.Logging: Errored.")
        err
    end
  end

  ## Server Callbacks

  def init(opts) do
    {:ok, opts}
  end

  def handle_call({:wait}, _from, state) do
    {:reply, nil, state}
  end

  def handle_cast({:execute, action}, state) do
    Logger.info(inspect(action))
    {:noreply, state}
  end
end
