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

    subscriptions = [
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
    ]

    subscriptions =
      if opts.remote_scheduler do
        [{"schedule/#{opts.remote_scheduler}", 0} | subscriptions]
      else
        subscriptions
      end

    children = [
      {Robotica.PluginRegistry, name: Robotica.PluginRegistry},
      {RoboticaCommon.Subscriptions, name: RoboticaCommon.Subscriptions},
      {Robotica.Executor, name: Robotica.Executor},
      {Tortoise.Connection,
       client_id: client_id,
       handler: {Robotica.Client, [remote_scheduler: opts.remote_scheduler]},
       user_name: opts.mqtt.user_name,
       password: opts.mqtt.password,
       server:
         {Tortoise.Transport.SSL,
          host: opts.mqtt.host, port: opts.mqtt.port, cacertfile: opts.mqtt.ca_cert_file},
       subscriptions: subscriptions}
    ]

    children =
      if opts.remote_scheduler do
        children
      else
        [
          {Robotica.Scheduler.Marks, name: Robotica.Scheduler.Marks},
          {Robotica.Scheduler.Executor, name: Robotica.Scheduler.Executor} | children
        ]
      end

    extra_children =
      opts.plugins
      |> Enum.with_index()
      |> Enum.map(fn {plugin, index} ->
        Supervisor.child_spec({plugin.module, plugin}, id: "plugin#{index}")
      end)

    Supervisor.init(children ++ extra_children, strategy: :one_for_one)
  end
end
