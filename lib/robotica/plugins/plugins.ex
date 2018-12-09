defmodule Robotica.Plugins do
  defmodule Plugin do
    @type t :: %__MODULE__{
            module: atom,
            location: String.t(),
            config: map,
            executor: pid | nil
          }
    @enforce_keys [:module, :location, :config]
    defstruct module: nil, location: nil, config: nil, executor: nil

    defmacro __using__(_opts) do
      quote do
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
      end
    end
  end

  defmodule Action do
    @type t :: %__MODULE__{
            lights: map() | nil,
            sound: map() | nil,
            music: map() | nil,
            timer_status: map() | nil,
            timer_cancel: map() | nil
          }
    defstruct message: nil,
              lights: nil,
              sound: nil,
              music: nil,
              timer_status: nil,
              timer_cancel: nil
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
