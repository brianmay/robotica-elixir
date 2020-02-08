defmodule Robotica.Plugin do
  @type t :: %__MODULE__{
          module: atom,
          location: String.t(),
          device: String.t(),
          config: map
        }
  @enforce_keys [:module, :location, :device, :config]
  defstruct module: nil, location: nil, device: nil, config: nil

  @callback config_schema :: map()

  defmacro __using__(_opts) do
    quote do
      @behaviour Robotica.Plugin

      @spec start_link(plugin :: Robotica.Plugins.Plugin.t()) ::
              {:ok, pid} | {:error, String.t()}
      def start_link(plugin) do
        with {:ok, pid} <- GenServer.start_link(__MODULE__, plugin, []) do
          Robotica.Executor.add(Robotica.Executor, plugin.location, plugin.device, pid)
          {:ok, pid}
        else
          err -> err
        end
      end

      def handle_call({:wait}, _from, state) do
        {:reply, nil, state}
      end
    end
  end

  @spec execute(server :: pid, action :: Action.t()) :: nil
  def execute(server, action) do
    GenServer.cast(server, {:execute, action})
    nil
  end

  @spec wait(server :: pid) :: nil
  def wait(server) do
    GenServer.call(server, {:wait}, 60000)
  end
end
