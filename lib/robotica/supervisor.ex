defmodule Robotica.Supervisor do
  use Supervisor

  defmodule State do
    @type t :: %__MODULE__{
            plugins: list(Robotica.Plugins.Plugin.t())
          }
    @enforce_keys [:plugins]
    defstruct plugins: []
  end

  @spec start_link(opts :: State.t()) :: {:ok, pid} | {:error, String.t()}
  def start_link(opts) do
    {:ok, pid} = Supervisor.start_link(__MODULE__, opts, name: __MODULE__)

    Robotica.Scheduler.load_schedule()

    {:ok, pid}
  end

  @impl true
  def init(opts) do
    {:ok, hostname} = :inet.gethostname()
    hostname = to_string(hostname)

    children = [
      {Robotica.Executor, name: Robotica.Executor},
      {Robotica.Scheduler.Executor, name: Robotica.Scheduler.Executor},
      {Tortoise.Connection,
       client_id: "robotica-#{hostname}",
       handler: {Robotica.Client, []},
       server: {Tortoise.Transport.Tcp, host: 'proxy.pri', port: 1883},
       subscriptions: [{"/execute/", 0}]}
    ]

    extra_children =
      Enum.map(opts.plugins, fn plugin ->
        plugin = %Robotica.Plugins.Plugin{
          plugin
          | register: fn pid ->
              Robotica.Executor.add(Robotica.Executor, plugin.location, pid)
              nil
            end
        }

        {plugin.module, plugin}
      end)

    Supervisor.init(children ++ extra_children, strategy: :one_for_one)
  end
end
