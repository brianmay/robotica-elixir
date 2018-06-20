defmodule Robotica.Supervisor do
  use Supervisor

  defmodule Plugin do
    @type t :: %__MODULE__{
            module: atom,
            config: map
          }
    @enforce_keys [:module, :config]
    defstruct module: nil, config: nil
  end

  defmodule State do
    @type t :: %__MODULE__{
            plugins: list(Plugin.t())
          }
    @enforce_keys [:plugins]
    defstruct plugins: []
  end

  @spec start_link(opts :: State.t()) :: {:ok, pid} | {:error, String.t()}
  def start_link(opts) do
    {:ok, pid} = Supervisor.start_link(__MODULE__, opts, name: __MODULE__)

    Enum.each(opts.plugins, fn plugin ->
      {:ok, _} = DynamicSupervisor.start_child(:dynamic, {plugin.module, plugin.config})
    end)

    {:ok, pid}
  end

  @impl true
  def init(_opts) do
    children = [
      {Robotica.Registry, name: Robotica.Registry},
      {DynamicSupervisor, name: :dynamic, strategy: :one_for_one}
    ]

    Supervisor.init(children, strategy: :one_for_one)
  end
end
