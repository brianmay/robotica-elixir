defmodule Robotica.Supervisor do
  @moduledoc """
  The top robotica supervisor
  """
  use Supervisor

  defmodule Config do
    @moduledoc """
    The top level robotica configuration
    """
    @type t :: %__MODULE__{
            remote_scheduler: String.t() | nil,
            plugins: list(Robotica.Plugin.t()),
            mqtt: map()
          }
    @enforce_keys [:remote_scheduler, :plugins, :mqtt]
    defstruct remote_scheduler: nil, plugins: [], mqtt: nil
  end

  @spec start_link(opts :: Config.t()) :: {:ok, pid} | {:error, String.t()}
  def start_link(%Config{} = opts) do
    {:ok, _pid} = Supervisor.start_link(__MODULE__, opts, name: __MODULE__)
  end

  @impl true
  def init(%Config{} = opts) do
    client_id = Robotica.Mqtt.get_tortoise_client_id()
    client_name = Robotica.Mqtt.get_tortoise_client_name()

    EventBus.register_topic(:schedule)
    EventBus.register_topic(:command_task)
    EventBus.register_topic(:command)
    EventBus.register_topic(:mark)
    EventBus.register_topic(:subscribe)
    EventBus.register_topic(:unsubscribe_all)

    EventBus.subscribe(
      {Robotica.RoboticaService, ["^command$", "^mark$", "^subscribe$", "^unsubscribe_all$"]}
    )

    subscriptions = []

    children =
      if opts.remote_scheduler do
        []
      else
        [
          {Robotica.Scheduler.Marks, name: Robotica.Scheduler.Marks},
          {Robotica.Scheduler.Executor, name: Robotica.Scheduler.Executor}
        ]
      end

    children = [
      {MqttPotion.Connection,
       name: client_name,
       host: opts.mqtt.host,
       port: opts.mqtt.port,
       ssl: true,
       force_ping: true,
       protocol_version: 5,
       client_id: client_id,
       keepalive: 30,
       username: opts.mqtt.user_name,
       password: opts.mqtt.password,
       tcp_opts: [
         :inet6
       ],
       ssl_opts: [
         verify: :verify_peer,
         cacertfile: opts.mqtt.ca_cert_file
       ],
       handler_pid: MqttPotion.Multiplexer,
       subscriptions: subscriptions},
      {MqttPotion.Multiplexer, mqtt_potion: client_name},
      {Robotica.Mqtt, []},
      {Finch, name: Robotica.Finch},
      {Robotica.PluginRegistry, name: Robotica.PluginRegistry}
      | children
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
