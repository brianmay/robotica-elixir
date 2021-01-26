defmodule Robotica.Supervisor do
  use Supervisor

  defmodule State do
    @type t :: %__MODULE__{
            plugins: list(RoboticaPlugins.Plugin.t()),
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

    EventBus.register_topic(:schedule)
    EventBus.register_topic(:request_schedule)
    EventBus.register_topic(:execute)
    EventBus.register_topic(:local_execute)
    EventBus.register_topic(:remote_execute)
    EventBus.register_topic(:mark)

    EventBus.subscribe(
      {Robotica.RoboticaService,
       ["^request_schedule$", "^local_execute$", "^remote_execute$", "^mark$"]}
    )

    children = [
      {Robotica.PluginRegistry, name: Robotica.PluginRegistry},
      {Robotica.Executor, name: Robotica.Executor},
      {Robotica.Scheduler.Marks, name: Robotica.Scheduler.Marks},
      {Robotica.Scheduler.Executor, name: Robotica.Scheduler.Executor},
      {Tortoise.Connection,
       client_id: client_id,
       handler: {Robotica.Client, []},
       user_name: opts.mqtt.user_name,
       password: opts.mqtt.password,
       server:
         {Tortoise.Transport.SSL,
          host: opts.mqtt.host, port: opts.mqtt.port, cacertfile: opts.mqtt.ca_cert_file},
       subscriptions: [
         {"execute", 0},
         {"mark", 0},
         {"request/all/#", 0},
         {"request/#{client_id}/#", 0},
       ]}
    ]

    extra_children =
      opts.plugins
      |> Enum.with_index()
      |> Enum.map(fn {plugin, index} ->
        Supervisor.child_spec({plugin.module, plugin}, id: "plugin#{index}")
      end)

    Supervisor.init(children ++ extra_children, strategy: :one_for_one)
  end
end
