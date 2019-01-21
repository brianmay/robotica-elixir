defmodule Robotica.Plugins do
  import Robotica.Types

  defmodule Plugin do
    @type t :: %__MODULE__{
            module: atom,
            location: String.t(),
            config: map,
            executor: pid | nil
          }
    @enforce_keys [:module, :location, :config]
    defstruct module: nil, location: nil, config: nil, executor: nil

    @callback config_schema :: map()

    defmacro __using__(_opts) do
      quote do
        @behaviour Plugin

        @spec start_link(plugin :: Robotica.Plugins.Plugin.t()) ::
                {:ok, pid} | {:error, String.t()}
        def start_link(plugin) do
          with {:ok, pid} <- GenServer.start_link(__MODULE__, plugin, []) do
            Robotica.Executor.add(plugin.executor, plugin.location, pid)
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
  end

  @spec execute(server :: pid, action :: Action.t()) :: nil
  def execute(server, action) do
    GenServer.cast(server, {:execute, action})
    nil
  end

  @spec wait(server :: pid) :: nil
  def wait(server) do
    GenServer.call(server, {:wait}, :infinity)
  end
end
