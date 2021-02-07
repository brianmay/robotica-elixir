defmodule Robotica.Plugins.LIFX do
  use GenServer
  use Robotica.Plugin

  require Logger

  import Robotica.Types
  alias Lifx.Protocol.HSBK
  alias Lifx.Protocol.HSBKS
  alias Robotica.Devices.Lifx.HSBKA
  alias Robotica.Devices.Lifx, as: RLifx

  alias Robotica.Plugins.Lifx.Animate
  alias Robotica.Plugins.Lifx.FixedColor

  @black %HSBK{
    hue: 0,
    saturation: 0,
    brightness: 0,
    kelvin: 3500
  }

  @black_alpha %HSBKA{
    hue: 0,
    saturation: 0,
    brightness: 0,
    kelvin: 3500,
    alpha: 100
  }

  defmodule Config do
    @type t :: %__MODULE__{
            label: String.t(),
            number: integer()
          }
    defstruct label: nil, number: 1
  end

  def config_schema do
    %{
      struct_type: Robotica.Plugins.LIFX.Config,
      label: {:string, true},
      number: {{:integer, 1}, false}
    }
  end

  defmodule TaskState do
    @type t :: %__MODULE__{
            priority: integer(),
            power: integer() | nil,
            colors: list(HSBKA.t()) | nil,
            pid: Task.t()
          }
    @enforce_keys [:priority, :pid]
    defstruct [:priority, :power, :colors, :pid]
  end

  defmodule State do
    @type t :: %__MODULE__{
            location: String.t(),
            device: String.t(),
            config: Config.t(),
            tasks: %{required(String.t()) => TaskState.t()},
            base_power: integer(),
            base_colors: list(HSBK.t())
          }
    defstruct [:location, :device, :config, :tasks, :base_power, :base_colors]
  end

  ## Server Callbacks

  @spec init(atom | %{:config => any, :device => any, :location => any, optional(any) => any}) ::
          {:ok, Robotica.Plugins.LIFX.State.t()}
  def init(plugin) do
    {:ok, _} = :timer.send_interval(5_000, :check_light)
    number = if plugin.config.number == nil, do: 1, else: plugin.config.number

    state = %State{
      location: plugin.location,
      device: plugin.device,
      config: plugin.config,
      tasks: %{},
      base_power: 0,
      base_colors: replicate(@black, number)
    }

    state = publish_device_state(state)
    {:ok, state}
  end

  @spec get_number(State.t()) :: integer()
  defp get_number(state) do
    if state.config.number == nil, do: 1, else: state.config.number
  end

  # @spec get_duration(map()) :: integer
  # defp get_duration(command) do
  #   case command.duration do
  #     nil -> 0
  #     duration -> duration * 1000
  #   end
  # end

  @spec device_to_string(State.t(), Lifx.Device.t() | nil) :: String.t()
  defp device_to_string(%State{} = state, nil) do
    "Lifx #{state.config.label}"
  end

  defp device_to_string(%State{} = state, %Lifx.Device{} = device) do
    "Lifx #{state.config.label} / Device #{device.id}/#{device.label}"
  end

  @spec replicate(any(), integer()) :: list(any())
  defp replicate(x, n), do: for(i <- 0..n, i > 0, do: x)

  # Publish state to MQTT

  @spec publish_device_tasks(State.t(), %{required(String.t()) => TaskState.t()}) :: :ok
  defp publish_device_tasks(%State{} = state, tasks) do
    list = Enum.map(tasks, fn {task_name, _} -> task_name end)

    case RoboticaPlugins.Mqtt.publish_state_json(state.location, state.device, list,
           topic: "tasks"
         ) do
      :ok ->
        :ok

      {:error, msg} ->
        Logger.error("#{device_to_string(state, nil)}: publish_device_color() got #{msg}")
    end

    :ok
  end

  @spec publish_device_state(State.t()) :: State.t()
  defp publish_device_state(%State{} = state) do
    :ok = publish_device_tasks(state, state.tasks)
    state
  end

  @spec publish_device_colors(State.t(), Lifx.Device.t(), list(HSBK.t())) :: :ok
  defp publish_device_colors(%State{} = state, %Lifx.Device{} = device, colors) do
    case RoboticaPlugins.Mqtt.publish_state_json(state.location, state.device, colors,
           topic: "colors"
         ) do
      :ok ->
        :ok

      {:error, msg} ->
        Logger.error("#{device_to_string(state, device)}: publish_device_color() got #{msg}")
    end

    :ok
  end

  @spec publish_device_power(State.t(), Lifx.Device.t(), integer()) :: :ok
  defp publish_device_power(%State{} = state, %Lifx.Device{} = device, power) do
    power = if power != 0, do: "ON", else: "OFF"

    case RoboticaPlugins.Mqtt.publish_state_raw(state.location, state.device, power,
           topic: "power"
         ) do
      :ok ->
        :ok

      {:error, msg} ->
        Logger.error("#{device_to_string(state, device)}: publish_device_power() got #{msg}")
    end

    :ok
  end

  @spec publish_device_error(State.t(), Lifx.Device.t() | nil, String.t()) :: :ok
  defp publish_device_error(%State{} = state, device, error) do
    power = "HARD_OFF"
    Logger.info("#{device_to_string(state, device)}: Got LIFX error #{error}.")

    case RoboticaPlugins.Mqtt.publish_state_raw(state.location, state.device, power,
           topic: "power"
         ) do
      :ok ->
        :ok

      {:error, msg} ->
        Logger.error(
          "#{device_to_string(state, device)}: publish_device_hard_off() power got #{msg}."
        )
    end

    case RoboticaPlugins.Mqtt.publish_state_raw(state.location, state.device, power,
           topic: "error",
           retain: false
         ) do
      :ok ->
        :ok

      {:error, msg} ->
        Logger.error(
          "#{device_to_string(state, device)}: publish_device_hard_off() error got #{msg}."
        )
    end

    :ok
  end

  # Recurse throught every online light

  @spec get_device(State.t(), (Light.Device.t() -> any())) :: any() | {:error, String.t()}
  defp get_device(state, callback) do
    devices = Enum.filter(Lifx.Client.devices(), &(&1.label == state.config.label))

    if length(devices) == 0 do
      publish_device_error(state, nil, "Device is offline")
      {:error, "Device is offline"}
    else
      devices
      |> hd()
      |> callback.()
    end
  end

  # Wrappers around LIFX functions to get state

  @spec get_power(State.t()) :: {:ok, integer()} | {:error, String.t()}
  defp get_power(%State{} = state) do
    get_device(state, fn device ->
      rc = Lifx.Device.get_power(device)

      case rc do
        {:ok, power} -> publish_device_power(state, device, power)
        {:error, error} -> publish_device_error(state, device, error)
      end

      rc
    end)
  end

  @spec get_colors(State.t()) ::
          {:ok, list(HSBK.t())} | {:error, String.t()}
  defp get_colors(%State{} = state) do
    get_device(state, fn device ->
      rc =
        case state.config.number do
          0 ->
            {:ok, []}

          1 ->
            case Lifx.Device.get_color(device) do
              {:ok, color} -> {:ok, [color]}
              {:error, error} -> {:error, error}
            end

          _ ->
            case Lifx.Device.get_extended_color_zones(device) do
              {:ok, %HSBKS{} = hsbks} -> {:ok, hsbks.list}
              {:error, error} -> {:error, error}
            end
        end

      case rc do
        {:ok, colors} -> publish_device_colors(state, device, colors)
        {:error, error} -> publish_device_error(state, device, error)
      end

      rc
    end)
  end

  # Wrappers around LIFX functions that publish updated state

  @spec set_color_wait(State.t(), HSBK.t(), integer()) :: :ok
  defp set_color_wait(%State{} = state, %HSBK{} = color, duration) do
    get_device(state, fn device ->
      rc = Lifx.Device.set_color_wait(device, color, duration)

      case rc do
        {:ok, _} -> publish_device_colors(state, device, [color])
        {:error, error} -> publish_device_error(state, device, error)
      end
    end)

    :ok
  end

  @spec set_power_wait(State.t(), integer()) :: :ok
  defp set_power_wait(%State{} = state, power) do
    get_device(state, fn device ->
      rc = Lifx.Device.set_power_wait(device, power)

      case rc do
        {:ok, _} -> publish_device_power(state, device, power)
        {:error, error} -> publish_device_error(state, device, error)
      end
    end)

    :ok
  end

  @spec on_wait(Robotica.Plugins.LIFX.State.t()) :: :ok
  def on_wait(%State{} = state) do
    set_power_wait(state, 65535)
  end

  @spec off_wait(Robotica.Plugins.LIFX.State.t()) :: :ok
  def off_wait(%State{} = state) do
    set_power_wait(state, 0)
  end

  @spec set_extended_color_zones_wait(State.t(), list(HSBK.t()), integer()) :: :ok
  defp set_extended_color_zones_wait(%State{} = state, colors, duration) do
    get_device(state, fn device ->
      colors = %Lifx.Protocol.HSBKS{list: colors, index: 0}
      rc = Lifx.Device.set_extended_color_zones_wait(device, colors, duration)

      case rc do
        {:ok, _} -> :ok = publish_device_colors(state, device, colors.list)
        {:error, error} -> :ok = publish_device_error(state, device, error)
      end
    end)

    :ok
  end

  # @spec debug_colors(list(Lifx.Protocol.HSBK.t{})) :: :ok
  # defp debug_colors(colors) do
  #   Enum.each(colors, fn color ->
  #     IO.puts("---> #{inspect(color)}")
  #   end)

  #   IO.puts("")
  #   :ok
  # end

  @spec set_colors(State.t(), list(Lifx.Protocol.HSBK.t({}))) :: :ok
  defp set_colors(state, colors) do
    duration = 0

    case state.config.number do
      0 ->
        nil

      1 ->
        :ok = set_color_wait(state, hd(colors), duration)

      _ ->
        :ok = set_extended_color_zones_wait(state, colors, duration)
    end
  end

  # Timer

  @spec merge_light_colors(list(list(HSBKA.t() | HSBK.t()))) :: list(HSBK.t())
  defp merge_light_colors(colors) do
    # Receives list of colors sorted by light, e.g. for 2 tasks with 4 lights.
    # [
    #   {%HSBK{}, %HSBKA{}, %HSBKA{}},
    #   {%HSBK{}, nil, %HSBKA{}},
    #   {%HSBK{}, %HSBKA{}, nil},
    #   {%HSBK{}, %HSBKA{}, %HSBKA{}},
    # ]
    # First item on each list is base color.
    #
    # Merges these colors:
    #
    # [%HSBK{}, %HSBK{}, %HSBK{}, %HSBK{}]

    Enum.map(colors, fn light_colors ->
      light_colors = Tuple.to_list(light_colors)
      [base_color | light_colors] = light_colors

      Enum.reduce(light_colors, base_color, fn color, base_color ->
        cond do
          color == nil ->
            base_color

          true ->
            alpha = color.alpha / 100
            base_alpha = (100 - color.alpha) / 100

            %HSBK{
              hue: round(base_color.hue * base_alpha + color.hue * alpha),
              saturation: round(base_color.saturation * base_alpha + color.saturation * alpha),
              brightness: round(base_color.brightness * base_alpha + color.brightness * alpha),
              kelvin: round(base_color.kelvin * base_alpha + color.kelvin * alpha)
            }
        end
      end)
    end)
  end

  @spec merge_colors(list(list(HSBKA.t() | nil)), list(HSBK.t())) :: list(HSBK.t())
  defp merge_colors(list_hsbkas, start_colors) do
    # Receives list of colors for each task. e.g. for 2 tasks with 4 lights
    # [
    #   nil,   # task not updated colors yet
    #   [%HSBKA{}, nil, %HSBKA{}, %HSBKA{}],
    #   [%HSBKA{}, %HSBKA{}, nil, %HSBKA{}]
    # ]
    # Merges these colors into start_colors:
    #
    # [%HSBK{}, %HSBK{}, %HSBK{}, %HSBK{}]

    list_hsbkas = Enum.reject(list_hsbkas, fn list -> list == nil end)
    Enum.zip([start_colors | list_hsbkas])
    |> merge_light_colors()
  end

  @spec merge_power(list(boolean | nil), integer) :: integer
  defp merge_power(power_list, base_power) do
    # Recieves a list of powers for each task, e.g. for 2 tasks
    # [nil, true]
    # Merges these into a start_power:
    # true
    Enum.reduce(power_list, base_power, fn power, base_power ->
      cond do
        power == nil -> base_power
        true -> power
      end
    end)
  end

  @spec handle_update(State.t()) :: State.t()
  defp handle_update(%State{} = state) do
    Logger.info("#{device_to_string(state, nil)}: update")

    base_power = state.base_power
    base_colors = state.base_colors

    Logger.info(
      "#{device_to_string(state, nil)}: base #{inspect(base_power)} #{inspect(base_colors)}"
    )

    list_tasks =
      state.tasks
      |> Enum.sort_by(fn {_, task} -> task.priority end)
      |> Enum.map(fn {_, task} -> task end)

    colors =
      list_tasks
      |> Enum.map(fn task -> task.colors end)
      |> merge_colors(base_colors)

    power =
      list_tasks
      |> Enum.map(fn task -> task.power end)
      |> merge_power(base_power)

    Logger.info("#{device_to_string(state, nil)}: GOT #{inspect(power)} #{inspect(colors)}")
    restore_device(state, {power, colors})
    state
  end

  @spec update_task_state(State.t(), pid(), String.t(), integer(), list(HSBKA)) :: State.t()
  defp update_task_state(state, pid, task_name, power, hsbkas) do
    Logger.info("#{device_to_string(state, nil)}: update_task_state #{task_name}")
    number = get_number(state)
    length = length(hsbkas)

    hsbkas =
      cond do
        length > number -> Enum.take(hsbkas, number)
        length < number -> hsbkas ++ replicate(nil, number - length)
        length == number -> hsbkas
      end

    cond do
      length(hsbkas) == number -> nil
    end

    task = Map.fetch!(state.tasks, task_name)

    if task.pid.pid == pid do
      Logger.info("#{device_to_string(state, nil)}: update_task_state #{task_name} same pid")
      task = %TaskState{task | colors: hsbkas, power: power}
      tasks = Map.put(state.tasks, task_name, task)
      state = %State{state | tasks: tasks}
      handle_update(state)
    else
      Logger.info("#{device_to_string(state, nil)}: update_task_state #{task_name} wrong pid")
      state
    end
  end

  # Add/remove tasks

  @spec task_exists?(State.t(), String.t()) :: boolean()
  def task_exists?(%State{} = state, task_name) do
    Map.has_key?(state.tasks, task_name)
  end

  @spec stop_task(State.t(), String.t()) :: :ok
  def stop_task(state, task_name) do
    case Map.fetch(state.tasks, task_name) do
      {:ok, task} -> Task.shutdown(task.pid)
      :error -> nil
    end

    :ok
  end

  @spec add_task(State.t(), String.t(), integer(), (() -> :ok)) :: State.t()
  defp add_task(%State{} = state, task_name, priority, function) do
    Logger.info("#{device_to_string(state, nil)}: add_task #{task_name}")
    already_exists = task_exists?(state, task_name)

    if already_exists do
      :ok = stop_task(state, task_name)
    end

    pid = Task.async(function)

    task = %TaskState{
      priority: priority,
      pid: pid
    }

    tasks = Map.put(state.tasks, task_name, task)
    %State{state | tasks: tasks}
  end

  @spec remove_task(State.t(), String.t()) :: State.t()
  defp remove_task(%State{} = state, task_name) do
    Logger.info("remove_task #{task_name}")

    :ok = stop_task(state, task_name)
    tasks = Map.delete(state.tasks, task_name)
    %State{state | tasks: tasks}
  end

  @spec remove_all_tasks(State.t()) :: State.t()
  def remove_all_tasks(%State{} = state) do
    Enum.reduce(state.tasks, state, fn {task_name, _}, state -> remove_task(state, task_name) end)
  end

  @spec keyword_list_to_map(values :: list) :: map
  defp keyword_list_to_map(values) do
    for {key, val} <- values, into: %{}, do: {key, val}
  end

  @spec handle_task_has_died(State.t(), pid()) :: State.t()
  defp handle_task_has_died(%State{} = state, pid) do
    Logger.info("#{device_to_string(state, nil)}: handle_task_has_died #{inspect(pid)}")

    tasks =
      state.tasks
      |> Enum.reject(fn {_, task} -> task.pid.pid == pid end)
      |> keyword_list_to_map()

    state = %State{
      state
      | tasks: tasks
    }

    state
    |> publish_device_state()
    |> handle_update()
  end

  @spec save_device(State.t()) ::
          {:ok, {integer(), list(Lifx.Protocol.HSBK.t())}} | {:error, String.t()}
  defp save_device(%State{} = state) do
    with {:ok, power} <- get_power(state),
         {:ok, colors} <- get_colors(state) do
      {:ok, {power, colors}}
    else
      {:error, error} -> {:error, error}
    end
  end

  @spec restore_device(State.t(), {integer(), list(Lifx.Protocol.HSBK.t())}) ::
          :ok | {:error, String.t()}
  def restore_device(state, {power, colors}) do
    with :ok <- set_colors(state, colors),
         :ok <- set_power_wait(state, power) do
      :ok
    else
      {:error, error} -> {:error, error}
    end
  end

  @spec do_command_stop(State.t(), map()) :: State.t()
  defp do_command_stop(state, %{stop: nil}), do: state

  defp do_command_stop(state, command) do
    Enum.reduce(command.stop, state, fn task, state ->
      remove_task(state, task)
    end)
  end

  @spec do_command(State.t(), map) :: State.t()

  defp do_command(%State{} = state, %{action: "turn_off"} = command) do
    Logger.debug("#{device_to_string(state, nil)}: turn_off")
    pid = self()
    number = get_number(state)
    colors = replicate(@black_alpha, number)

    sender = fn power, colors ->
      GenServer.cast(pid, {:update, self(), "default", power, colors})
      :ok
    end

    state
    |> do_command_stop(command)
    |> add_task("default", 100, fn -> FixedColor.go(sender, 0, colors) end)
    |> publish_device_state()
  end

  defp do_command(%State{} = state, %{action: "stop"} = command) do
    Logger.debug("#{device_to_string(state, nil)}: stop")

    state
    |> do_command_stop(command)
    |> publish_device_state()
    |> handle_update()
  end

  defp do_command(%State{} = state, %{action: "turn_on"} = command) do
    Logger.debug("#{device_to_string(state, nil)}: turn_on")
    number = get_number(state)

    colors =
      case RLifx.get_colors_from_command(number, command, 0) do
        {:ok, colors} ->
          colors

        {:error, error} ->
          Logger.error("Got error in lifx get_colors_from_command: #{inspect(error)}")
          replicate(@black_alpha, number)
      end

    pid = self()

    sender = fn power, colors ->
      GenServer.cast(pid, {:update, self(), "default", power, colors})
      :ok
    end

    state
    |> do_command_stop(command)
    |> add_task("default", 100, fn -> FixedColor.go(sender, 65535, colors) end)
    |> publish_device_state()
  end

  defp do_command(%State{} = state, %{action: "flash"} = command) do
    Logger.debug("#{device_to_string(state, nil)}: flash")
    pid = self()
    number = get_number(state)
    state = do_command_stop(state, command)

    color = %HSBKA{
      hue: command.color.hue,
      saturation: command.color.saturation,
      brightness: command.color.brightness,
      kelvin: command.color.kelvin,
      alpha: command.color.alpha
    }

    animation = %{
      name: "flash",
      priority: 900,
      repeat: 2,
      frames: [
        %{
          sleep: 500,
          repeat: 1,
          color: color,
          colors: nil
        },
        %{
          sleep: 500,
          repeat: 1,
          color: %HSBKA{
            hue: 0,
            saturation: 0,
            brightness: 0,
            kelvin: 3500,
            alpha: 50
          },
          colors: nil
        }
      ]
    }

    sender = fn power, colors ->
      GenServer.cast(pid, {:update, self(), animation.name, power, colors})
      :ok
    end

    state
    |> add_task(animation.name, animation.priority, fn ->
      Animate.go(sender, number, animation)
    end)
    |> publish_device_state()
  end

  defp do_command(%State{} = state, %{action: "animate"} = command) do
    Logger.debug("#{device_to_string(state, nil)}: animate")
    pid = self()
    number = get_number(state)
    state = do_command_stop(state, command)

    case command.animation do
      nil ->
        state

      animation ->
        sender = fn power, hsbkas ->
          GenServer.cast(pid, {:update, self(), animation.name, power, hsbkas})
          :ok
        end

        state
        |> add_task(animation.name, animation.priority, fn ->
          Animate.go(sender, number, animation)
        end)
        |> publish_device_state()
    end
  end

  defp do_command(%State{} = state, command) do
    Logger.info("#{device_to_string(state, nil)}: Unknown command #{command.action}")
    state
  end

  @spec handle_command(state :: State.t(), command :: map()) :: State.t()
  defp handle_command(%State{} = state, command) do
    state
    |> do_command(command)
  end

  def handle_cast({:mqtt, _, :command, command}, %State{} = state) do
    state =
      case Robotica.Config.validate_lights_command(command) do
        {:ok, command} ->
          handle_command(state, command)

        {:error, error} ->
          Logger.error(
            "#{device_to_string(state, nil)}: Invalid lifx command received: #{inspect(error)}."
          )

          state
      end

    {:noreply, state}
  end

  def handle_cast({:update, pid, task_name, power, hsbkas}, %State{} = state) do
    state = update_task_state(state, pid, task_name, power, hsbkas)
    {:noreply, state}
  end

  def handle_cast({:execute, action}, %State{} = state) do
    state =
      case action.lights do
        nil -> state
        command -> handle_command(state, command)
      end

    {:noreply, state}
  end

  def handle_info(:check_light, %State{} = state) do
    state =
      if state.tasks == %{} do
        case save_device(state) do
          {:ok, {power, color}} ->
            %State{state | base_power: power, base_colors: color}

          {:error, error} ->
            Logger.info(
              "#{device_to_string(state, nil)}: check_light cannot get light state: #{error}"
            )

            state
        end
      else
        state
      end

    {:noreply, state}
  end

  def handle_info({:DOWN, _ref, :process, pid, _reason}, %State{} = state) do
    new_state = handle_task_has_died(state, pid)
    {:noreply, new_state}
  end

  def handle_info({_ref, _status}, state) do
    {:noreply, state}
  end
end
