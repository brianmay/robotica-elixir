defmodule Robotica.Supervisor do
  use Supervisor

  defmodule State do
    @type t :: %__MODULE__{
            plugins: list(Robotica.Plugins.Plugin.t()),
            location: String.t()
          }
    @enforce_keys [:plugins, :location]
    defstruct plugins: [], location: nil
  end

  @spec start_link(opts :: State.t()) :: {:ok, pid} | {:error, String.t()}
  def start_link(opts) do
    {:ok, pid} = Supervisor.start_link(__MODULE__, opts, name: __MODULE__)

    Enum.each(opts.plugins, fn plugin ->
      plugin = %Robotica.Plugins.Plugin{
        plugin
        | register: fn pid ->
            Robotica.Executor.add(Robotica.Executor, plugin.location, pid)
            nil
          end
      }

      {:ok, _pid} = DynamicSupervisor.start_child(:dynamic, {plugin.module, plugin})
    end)

    {:ok, pid}
  end

  @impl true
  def init(opts) do
    children = [
      {Robotica.Executor, name: Robotica.Executor},
      {DynamicSupervisor, name: :dynamic, strategy: :one_for_one},
      {Tortoise.Connection,
       client_id: Robotica.Client,
       handler: {Robotica.Client, []},
       server: {Tortoise.Transport.Tcp, host: 'proxy.pri', port: 1883},
       subscriptions: [{"/action/#{opts.location}/", 0}]}
    ]

    Supervisor.init(children, strategy: :one_for_one)
  end
end
