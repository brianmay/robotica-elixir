defmodule Robotica.Supervisor do
  @moduledoc """
  The top robotica supervisor
  """
  use Supervisor

  defmodule State do
    @moduledoc """
    The top level robotica configuration
    """
    @type t :: %__MODULE__{
            plugins: list(Robotica.Plugin.t()),
            mqtt: map()
          }
    @enforce_keys [:plugins, :mqtt]
    defstruct plugins: [], mqtt: nil
  end

  @spec start_link(opts :: State.t()) :: {:ok, pid} | {:error, String.t()}
  def start_link(opts) do
    {:ok, _pid} = Supervisor.start_link(__MODULE__, opts, name: __MODULE__)
  end

  @impl true
  def init(opts) do
    client_id = RoboticaCommon.Mqtt.get_tortoise_client_id()

    EventBus.register_topic(:schedule)
    EventBus.register_topic(:request_schedule)
    EventBus.register_topic(:command_task)
    EventBus.register_topic(:command)
    EventBus.register_topic(:mark)
    EventBus.register_topic(:subscribe)
    EventBus.register_topic(:unsubscribe_all)

    EventBus.subscribe(
      {Robotica.RoboticaService,
       ["^request_schedule$", "^command$", "^mark$", "^subscribe$", "^unsubscribe_all$"]}
    )

    children = [
      {Robotica.PluginRegistry, name: Robotica.PluginRegistry},
      {RoboticaCommon.Subscriptions, name: RoboticaCommon.Subscriptions},
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

         # Dynamic subscriptions,
         # Here because of https://github.com/gausby/tortoise/issues/130
         # Should be done in subscriptions.ex
         # All plugins
         {"command/#", 0},
         # sonoff plugin
         {"stat/#", 0},
         {"tele/#", 0},
         # robotica_ui and robotica_face
         {"state/#", 0}
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
