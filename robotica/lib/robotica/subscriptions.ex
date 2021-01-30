defmodule Robotica.Subscriptions do
  use GenServer
  require Logger

  defmodule State do
    @type t :: %__MODULE__{
            subscriptions: %{required(list({atom(), String.t()})) => list(pid)}
          }
    defstruct subscriptions: %{}
  end

  ## Client API

  @spec start_link(opts :: list) :: {:ok, pid} | {:error, String.t()}
  def start_link(opts) do
    GenServer.start_link(__MODULE__, :ok, opts)
  end

  @spec subscribe(topic :: list(String.t()), label :: atom(), pid :: pid) :: :ok
  def subscribe(topic, label, pid) do
    GenServer.call(Robotica.Subscriptions, {:subscribe, topic, label, pid})
  end

  @spec message(topic :: list(String.t()), message :: map()) :: :ignored | :processed
  def message(topic, message) do
    GenServer.call(Robotica.Subscriptions, {:message, topic, message})
  end

  ## Server Callbacks

  def init(:ok) do
    {:ok, %State{}}
  end

  @spec handle_add(state :: State.t(), topic :: list(String.t()), label :: atom(), pid :: pid) ::
          State.t()
  defp handle_add(state, topic, label, pid) do
    _ref = Process.monitor(pid)
    topic_str = Enum.join(topic, "/")

    pids =
      case Map.get(state.subscriptions, topic, []) do
        [] ->
          client_id = RoboticaPlugins.Mqtt.get_tortoise_client_id()

          topics = [
            {topic_str, 0}
          ]

          Logger.debug("Subscribing to #{topic_str} pid #{inspect(pid)}.")
          :ok = Tortoise.Connection.subscribe_sync(client_id, topics)

          [{label, pid}]

        pids ->
          Logger.debug("Adding subscription #{topic_str} to pid #{inspect(pid)}.")
          [{label, pid} | pids]
      end

    subscriptions = Map.put(state.subscriptions, topic, pids)
    %State{state | subscriptions: subscriptions}
  end

  def handle_call({:subscribe, topic, label, pid}, _from, state) do
    new_state = handle_add(state, topic, label, pid)
    {:reply, nil, new_state}
  end

  def handle_call({:message, topic, message}, _from, state) do
    processed =
      Map.get(state.subscriptions, topic, [])
      |> Enum.reduce(:ignored, fn {label, pid}, _ ->
        Robotica.Plugin.mqtt(pid, topic, label, message)
        :processed
      end)

    {:reply, processed, state}
  end

  @spec keyword_list_to_map(values :: list) :: map
  defp keyword_list_to_map(values) do
    for {key, val} <- values, into: %{}, do: {key, val}
  end

  @spec delete_pid_from_list(list, pid) :: list
  defp delete_pid_from_list(list, pid) do
    Enum.reject(list, fn {_, list_pid} -> list_pid == pid end)
  end

  def handle_info({{Tortoise, _}, _, _}, state) do
    {:noreply, state}
  end

  def handle_info({:DOWN, _ref, :process, pid, _reason}, state) do
    Logger.debug("Removing subscriptions from pid #{inspect(pid)}.")

    new_subscriptions =
      state.subscriptions
      |> Enum.reject(fn {_, l} -> length(l) == 0 end)
      |> Enum.map(fn {topic, l} -> {topic, delete_pid_from_list(l, pid)} end)

    Enum.each(new_subscriptions, fn
      {topic, []} ->
        client_id = RoboticaPlugins.Mqtt.get_tortoise_client_id()
        topic_str = Enum.join(topic, "/")
        Logger.debug("Unsubscribing from #{topic_str}.")
        Tortoise.Connection.unsubscribe(client_id, [topic_str])

      {_, _} ->
        nil
    end)

    new_subscriptions =
      new_subscriptions
      |> Enum.reject(fn {_, l} -> length(l) == 0 end)
      |> keyword_list_to_map()

    new_state = %State{state | subscriptions: new_subscriptions}

    {:noreply, new_state}
  end
end
