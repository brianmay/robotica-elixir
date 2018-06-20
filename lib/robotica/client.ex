defmodule Robotica.Client do
  require Logger

  defmodule State do
    @type t :: %__MODULE__{
            location: String.t()
          }
    @enforce_keys [:location]
    defstruct location: nil
  end

  @behaviour Tortoise.Handler

  @spec start(opts :: State.t()) :: {:ok, pid}
  def start(opts) do
    location = opts.location

    Tortoise.Supervisor.start_child(
      client_id: Robotica.Client,
      handler: {Robotica.Client, []},
      server: {Tortoise.Transport.Tcp, host: 'proxy.pri', port: 1883},
      subscriptions: [{"/action/#{location}/", 0}]
    )
  end

  @spec init(opts :: State.t()) :: {:ok, State.t()}
  def init(opts) do
    {:ok, opts}
  end

  def connection(:up, state) do
    Logger.info("Connection has been established")
    {:ok, state}
  end

  def connection(:down, state) do
    Logger.warn("Connection has been dropped")
    {:ok, state}
  end

  def subscription(:up, topic, state) do
    Logger.info("Subscribed to #{topic}")
    {:ok, state}
  end

  def subscription({:warn, [requested: req, accepted: qos]}, topic, state) do
    Logger.warn("Subscribed to #{topic}; requested #{req} but got accepted with QoS #{qos}")
    {:ok, state}
  end

  def subscription({:error, reason}, topic, state) do
    Logger.error("Error subscribing to #{topic}; #{inspect(reason)}")
    {:ok, state}
  end

  def subscription(:down, topic, state) do
    Logger.info("Unsubscribed from #{topic}")
    {:ok, state}
  end

  def handle_message(topic, publish, state) do
    Logger.info("#{Enum.join(topic, "/")} #{inspect(publish)}")
    message = Poison.decode!(publish)
    [_, _, location, _] = topic
    locations = [location]
    actions = [message]

    Enum.each(actions, fn action ->
      Enum.each(locations, fn location ->
        plugins = Robotica.Registry.lookup(Robotica.Registry, location)

        Enum.each(plugins, fn plugin ->
          Robotica.Plugins.execute(plugin, action)
        end)

        Enum.each(plugins, fn plugin ->
          Robotica.Plugins.wait(plugin)
        end)
      end)
    end)

    {:ok, state}
  end

  def terminate(reason, _state) do
    Logger.warn("Client has been terminated with reason: #{inspect(reason)}")
    :ok
  end
end
