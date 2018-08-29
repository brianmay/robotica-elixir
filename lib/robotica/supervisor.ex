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
    {:ok, _pid} = Supervisor.start_link(__MODULE__, opts, name: __MODULE__)
  end

  def get_tortoise_client_id do
    {:ok, hostname} = :inet.gethostname()
    hostname = to_string(hostname)
    "robotica-#{hostname}"
  end

  @impl true
  def init(opts) do
    children = [
      {Robotica.Executor, name: Robotica.Executor},
      {Robotica.Scheduler.Executor, name: Robotica.Scheduler.Executor},
      {Tortoise.Connection,
       client_id: get_tortoise_client_id(),
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
