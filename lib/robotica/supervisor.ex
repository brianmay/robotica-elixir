defmodule Robotica.Supervisor do
  use Supervisor

  defmodule State do
    @type t :: %__MODULE__{
            plugins: list(Robotica.Plugins.Plugin.t()),
            mqtt: map()
          }
    @enforce_keys [:plugins, :mqtt]
    defstruct plugins: [], mqtt: nil
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
    client_id = get_tortoise_client_id()

    EventBus.register_topic(:execute)
    EventBus.register_topic(:done)

    children = [
      {Robotica.Executor, name: Robotica.Executor},
      {Robotica.Scheduler.Marks, name: Robotica.Scheduler.Marks},
      {Robotica.Scheduler.Executor, name: Robotica.Scheduler.Executor},
      {Tortoise.Connection,
       client_id: client_id,
       handler: {Robotica.Client, []},
       server: {Tortoise.Transport.Tcp, host: opts.mqtt.host, port: opts.mqtt.port},
       subscriptions: [
         {"execute", 0},
         {"mark", 0},
         {"request/all/#", 0},
         {"request/#{client_id}/#", 0}
       ]}
    ]

    extra_children =
      Enum.map(opts.plugins, fn plugin ->
        plugin = %Robotica.Plugins.Plugin{
          plugin
          | executor: Robotica.Executor
        }

        {plugin.module, plugin}
      end)

    Supervisor.init(children ++ extra_children, strategy: :one_for_one)
  end
end
