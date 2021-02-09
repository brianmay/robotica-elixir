defmodule Ceryx.Supervisor do
  use Supervisor

  defmodule State do
    @type t :: %__MODULE__{
            mqtt: map()
          }
    @enforce_keys [:mqtt]
    defstruct mqtt: nil
  end

  @spec start_link(opts :: State.t()) :: {:ok, pid} | {:error, String.t()}
  def start_link(opts) do
    {:ok, _pid} = Supervisor.start_link(__MODULE__, opts, name: __MODULE__)
  end

  @impl true
  def init(opts) do
    client_id = RoboticaPlugins.Mqtt.get_tortoise_client_id()

    EventBus.register_topic(:schedule)
    EventBus.register_topic(:request_schedule)
    EventBus.register_topic(:execute)
    EventBus.register_topic(:command)
    EventBus.register_topic(:mark)
    EventBus.register_topic(:subscribe)
    EventBus.register_topic(:unsubscribe_all)

    EventBus.subscribe(
      {Ceryx.CeryxService,
       ["^request_schedule$", "^command$", "^mark$", "^subscribe$", "^unsubscribe_all$"]}
    )

    children = [
      {RoboticaPlugins.Subscriptions, name: RoboticaPlugins.Subscriptions},
      {Tortoise.Connection,
       client_id: client_id,
       handler: {Ceryx.Client, []},
       user_name: opts.mqtt.user_name,
       password: opts.mqtt.password,
       server:
         {Tortoise.Transport.SSL,
          host: opts.mqtt.host, port: opts.mqtt.port, cacertfile: opts.mqtt.ca_cert_file},
       subscriptions: [
         {"execute", 0},
         {"schedule/robotica-nerves-f447", 0},

         # Dynamic subscriptions,
         # Here because of https://github.com/gausby/tortoise/issues/130
         # Should be done in subscriptions.ex

         # robotica_ui and robotica_face
         {"state/#", 0}
       ]}
    ]

    Supervisor.init(children, strategy: :one_for_one)
  end
end
