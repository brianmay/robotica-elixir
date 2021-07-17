defmodule RoboticaCommon.Subscriptions do
  @moduledoc """
  Implement per process MQTT subscriptions
  """
  use GenServer
  require Logger

  defmodule State do
    @moduledoc """
    Define current state of Subscriptions.
    """
    @type t :: %__MODULE__{
            subscriptions: %{required(list({atom(), String.t(), :json | :raw})) => list(pid)},
            last_message: %{required(list(String.t())) => any()},
            monitor: %{required(pid) => reference()}
          }
    defstruct subscriptions: %{}, last_message: %{}, monitor: %{}
  end

  ## Client API

  @spec start_link(opts :: list) :: {:ok, pid} | {:error, String.t()}
  def start_link(opts) do
    GenServer.start_link(__MODULE__, :ok, opts)
  end

  @spec subscribe(
          topic :: list(String.t()),
          label :: atom(),
          pid :: pid,
          format :: :json | :raw,
          resend :: :resend | :no_resend
        ) :: :ok
  def subscribe(topic, label, pid, format, resend) do
    GenServer.call(__MODULE__, {:subscribe, topic, label, pid, format, resend}, 40_000)
  end

  @spec unsubscribe_all(pid :: pid) :: :ok
  def unsubscribe_all(pid) do
    GenServer.call(__MODULE__, {:unsubscribe_all, pid}, 40_000)
  end

  @spec message(topic :: list(String.t()), message :: String.t(), retain :: boolean()) :: :ok
  def message(topic, message, retain) do
    GenServer.cast(__MODULE__, {:message, topic, message, retain})
  end

  ## private

  @spec get_message_format(String.t(), :json | :raw) :: {:ok, any()} | {:error, String.t()}
  def get_message_format(message, :json) do
    case Poison.decode(message) do
      {:ok, message} -> {:ok, message}
      {:error, error} -> {:error, "Error #{inspect(error)}"}
    end
  end

  def get_message_format(message, :raw), do: {:ok, message}

  ## Server Callbacks

  def init(:ok) do
    {:ok, %State{}}
  end

  def retry(_func, 0), do: :error

  def retry(func, tries) do
    Logger.info("Trying")

    case func.() do
      :ok ->
        Logger.info("got OK")
        :ok

      {:error, :timeout} ->
        Logger.info("got timeout")
        retry(func, tries - 1)
    end
  end

  @spec send_to_client(topic :: list(String.t()), any(), pid, atom(), String.t()) :: :ok
  defp send_to_client(topic, label, pid, format, raw_message) do
    case get_message_format(raw_message, format) do
      {:ok, message} ->
        Logger.debug(
          "Dispatching #{inspect(topic)} #{inspect(raw_message)} #{inspect(format)} #{inspect(message)}."
        )

        :ok = GenServer.cast(pid, {:mqtt, topic, label, message})

      {:error, message} ->
        Logger.error("Cannot decode #{inspect(message)} using #{inspect(format)}.")
    end
  end

  @spec handle_add(
          state :: State.t(),
          topic :: list(String.t()),
          label :: any(),
          pid :: pid,
          format :: :json | :raw,
          resend :: :resend | :no_resend
        ) ::
          State.t()
  defp handle_add(state, topic, label, pid, format, resend) do
    state =
      if Map.has_key?(state.monitor, pid) do
        ref = Process.monitor(pid)
        monitor = Map.put(state.monitor, pid, ref)
        %State{state | monitor: monitor}
      else
        state
      end

    topic_str = Enum.join(topic, "/")

    pids =
      case Map.get(state.subscriptions, topic, nil) do
        nil ->
          subscription = {topic_str, 0}
          client_name = RoboticaCommon.Mqtt.get_tortoise_client_name()

          # Logger.info("- Unsubscribing to #{topic_str} pid #{inspect(pid)}.")
          # MqttPotion.unsubscribe(client_name, topic_str)
          Logger.info("- Subscribing to #{topic_str} pid #{inspect(pid)}.")
          MqttPotion.subscribe(client_name, subscription)

          Logger.debug("Adding pid #{inspect(pid)} to new subscription #{topic_str}.")
          [{label, pid, format}]

        pids ->
          Logger.debug("Adding pid #{inspect(pid)} to old subscription #{topic_str}.")
          [{label, pid, format} | pids]
      end

    subscriptions = Map.put(state.subscriptions, topic, pids)

    # resend last message to new client
    case {resend, Map.fetch(state.last_message, topic)} do
      {:resend, {:ok, last_message}} ->
        Logger.debug("Resending last message to #{inspect(pid)} from subscription #{topic_str}.")
        :ok = send_to_client(topic, label, pid, format, last_message)

      _ ->
        nil
    end

    %State{state | subscriptions: subscriptions}
  end

  def handle_call({:subscribe, topic, label, pid, format, resend}, _from, state) do
    new_state = handle_add(state, topic, label, pid, format, resend)
    {:reply, :ok, new_state}
  end

  def handle_call({:unsubscribe_all, pid}, _from, state) do
    new_state = handle_unsubscribe_all(pid, state)
    {:reply, :ok, new_state}
  end

  def handle_cast({:message, topic, message, retain}, state) do
    Logger.debug("Got message #{inspect(topic)} #{inspect(message)}.")

    last_message = Map.put(state.last_message, topic, message)
    state = %State{state | last_message: last_message}

    Map.get(state.subscriptions, topic, [])
    |> Enum.each(fn {label, pid, format} ->
      :ok = send_to_client(topic, label, pid, format, message)
    end)

    {:noreply, state}
  end

  @spec keyword_list_to_map(values :: list) :: map
  defp keyword_list_to_map(values) do
    for {key, val} <- values, into: %{}, do: {key, val}
  end

  @spec delete_pid_from_list(list, pid) :: list
  defp delete_pid_from_list(list, pid) do
    Enum.reject(list, fn {_, list_pid, _} -> list_pid == pid end)
  end

  def handle_info({{Tortoise, _}, _, _}, state) do
    {:noreply, state}
  end

  def handle_info({:DOWN, ref, :process, pid, reason}, state) do
    Logger.debug("Process #{inspect(pid)} #{inspect(ref)} died reason #{inspect(reason)}.")
    new_state = handle_unsubscribe_all(pid, state)
    {:noreply, new_state}
  end

  defp handle_unsubscribe_all(pid, state) do
    Logger.info("Removing pid #{inspect(pid)} from all subscriptions.")
    monitor = Map.delete(state.monitor, pid)

    new_subscriptions =
      state.subscriptions
      |> Enum.map(fn {topic, l} -> {topic, delete_pid_from_list(l, pid)} end)
      |> keyword_list_to_map()

    Enum.each(new_subscriptions, fn
      {topic, []} ->
        client_name = RoboticaCommon.Mqtt.get_tortoise_client_name()
        topic_str = Enum.join(topic, "/")
        Logger.info("+ Unsubscribing from #{topic_str}.")
        MqttPotion.unsubscribe(client_name, topic_str)

      {_, _} ->
        nil
    end)

    new_subscriptions =
      new_subscriptions
      |> Enum.reject(fn
        {_, []} -> true
        {_, _} -> false
      end)
      |> keyword_list_to_map()

    %State{state | subscriptions: new_subscriptions, monitor: monitor}
  end
end
