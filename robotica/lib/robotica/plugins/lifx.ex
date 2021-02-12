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

  defmodule SceneState do
    @type t :: %__MODULE__{
            priority: integer(),
            power: integer() | nil,
            colors: list(HSBKA.t()) | nil,
            task: Task.t()
          }
    @enforce_keys [:priority, :task]
    defstruct [:priority, :power, :colors, :task]
  end

  defmodule State do
    @type t :: %__MODULE__{
            location: String.t(),
            device: String.t(),
            config: Config.t(),
            scenes: %{required(String.t()) => SceneState.t()},
            base_power: integer(),
            base_colors: list(HSBK.t())
          }
    defstruct [:location, :device, :config, :scenes, :base_power, :base_colors]
  end

  ## Server Callbacks

  @spec init(atom | %{:config => any, :device => any, :location => any, optional(any) => any}) ::
          {:ok, Robotica.Plugins.LIFX.State.t()}
  def init(plugin) do
    number = if plugin.config.number == nil, do: 1, else: plugin.config.number

    state = %State{
      location: plugin.location,
      device: plugin.device,
      config: plugin.config,
      scenes: %{},
      base_power: 0,
      base_colors: replicate(@black, number)
    }

    state = poll_device(state)
    state = publish_device_state(state)

    :ok = Lifx.Client.add_handler(self())
    :ok = Lifx.Poller.add_handler(self())
    {:ok, state}
  end

  @spec get_number(State.t()) :: integer()
  defp get_number(state) do
    if state.config.number == nil, do: 1, else: state.config.number
  end

  @spec merge_maps(map(), map()) :: map()
  defp merge_maps(map1, map2) do
    Map.merge(map1, map2, fn
      _, value, nil -> value
      _, _, value -> value
    end)
  end

  @spec apply_scenes_to_command(map(), State.t()) :: map()
  defp apply_scenes_to_command(%{scene: scene} = command, %State{} = state) do
    scene
    |> Robotica.Config.get_scene()
    |> Enum.reduce(%{}, fn scene, command ->
      got_location? = scene.locations == nil or Enum.member?(scene.locations, state.location)
      got_device? = scene.devices == nil or Enum.member?(scene.devices, state.device)

      if got_location? and got_device? do
        merge_maps(command, scene.lights())
      else
        command
      end
    end)
    |> merge_maps(command)
    |> Map.put(:scene, scene)
  end

  # @spec get_duration(map()) :: integer
  # defp get_duration(command) do
  #   case command.duration do
  #     nil -> 0
  #     duration -> duration * 1000
  #   end
  # end

  @spec get_priority(map(), integer) :: integer
  defp get_priority(command, default) do
    case command.priority do
      nil -> default
      priority -> priority
    end
  end

  @spec device_to_string(State.t(), Lifx.Device.t() | nil) :: String.t()
  defp device_to_string(%State{} = state, nil) do
    "Lifx #{state.config.label}"
  end

  defp device_to_string(%State{} = state, %Lifx.Device{} = device) do
    "Lifx #{state.config.label} / Device #{device.id}/#{device.label}"
  end

  @spec replicate(any(), integer()) :: list(any())
  defp replicate(x, n), do: for(i <- 0..n, i > 0, do: x)

  @spec poll_device(State.t()) :: State.t()
  def poll_device(state) do
    if state.scenes == %{} do
      case save_device(state) do
        {:ok, {power, color}} ->
          %State{state | base_power: power, base_colors: color}

        {:error, _} ->
          state
      end
    else
      state
    end
  end

  # Publish state to MQTT

  @spec publish_raw(State.t(), Lifx.Device.t() | nil, String.t(), String.t()) :: :ok
  defp publish_raw(%State{} = state, device, topic, value) do
    case RoboticaPlugins.Mqtt.publish_state_raw(state.location, state.device, value, topic: topic) do
      :ok ->
        :ok

      {:error, msg} ->
        Logger.error("#{device_to_string(state, device)}: publish_raw() got #{msg}")
    end

    :ok
  end

  @spec publish_json(State.t(), Lifx.Device.t() | nil, String.t(), map() | list()) :: :ok
  defp publish_json(%State{} = state, device, topic, value) do
    case RoboticaPlugins.Mqtt.publish_state_json(state.location, state.device, value, topic: topic) do
      :ok ->
        :ok

      {:error, msg} ->
        Logger.error("#{device_to_string(state, device)}: publish_raw() got #{msg}")
    end

    :ok
  end

  @spec publish_device_scenes(State.t(), %{required(String.t()) => SceneState.t()}) :: :ok
  defp publish_device_scenes(%State{} = state, scenes) do
    scene_list = Enum.map(scenes, fn {scene_name, _} -> scene_name end)
    :ok = publish_json(state, nil, "scenes", scene_list)

    priority_list =
      Enum.map(scenes, fn {_, %SceneState{priority: priority}} -> priority end) |> Enum.uniq()

    :ok = publish_json(state, nil, "priorities", priority_list)

    :ok
  end

  @spec publish_device_state(State.t()) :: State.t()
  defp publish_device_state(%State{} = state) do
    :ok = publish_device_scenes(state, state.scenes)
    state
  end

  @spec publish_device_colors(State.t(), Lifx.Device.t(), list(HSBK.t())) :: :ok
  defp publish_device_colors(%State{} = state, %Lifx.Device{} = device, colors) do
    :ok = publish_json(state, device, "colors", colors)
    :ok
  end

  @spec publish_device_power(State.t(), Lifx.Device.t(), integer()) :: :ok
  defp publish_device_power(%State{} = state, %Lifx.Device{} = device, power) do
    power = if power != 0, do: "ON", else: "OFF"
    :ok = publish_raw(state, device, "power", power)
    :ok = publish_raw(state, device, "error", "")
    :ok
  end

  @spec publish_device_hard_off(State.t(), Lifx.Device.t() | nil) :: :ok
  defp publish_device_hard_off(%State{} = state, device) do
    power = "HARD_OFF"
    :ok = publish_raw(state, device, "power", power)
    :ok = publish_raw(state, device, "error", "")
    :ok
  end

  @spec publish_device_error(State.t(), Lifx.Device.t() | nil, String.t()) :: :ok
  defp publish_device_error(%State{} = state, device, error) do
    :ok = publish_raw(state, device, "error", error)
    :ok
  end

  # Recurse throught every online light

  @spec get_device(State.t(), (Lifx.Device.t() -> any())) :: any() | {:error, String.t()}
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

  @spec set_colors(State.t(), list(Lifx.Protocol.HSBK.t())) :: :ok
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
    # Receives list of colors sorted by light, e.g. for 2 scenes with 4 lights.
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
              hue: base_color.hue * base_alpha + color.hue * alpha,
              saturation: base_color.saturation * base_alpha + color.saturation * alpha,
              brightness: base_color.brightness * base_alpha + color.brightness * alpha,
              kelvin: base_color.kelvin * base_alpha + color.kelvin * alpha
            }
        end
      end)
    end)
  end

  @spec merge_colors(list(list(HSBKA.t() | nil)), list(HSBK.t())) :: list(HSBK.t())
  defp merge_colors(list_hsbkas, start_colors) do
    # Receives list of colors for each scene. e.g. for 2 scenes with 4 lights
    # [
    #   nil,   # scene not updated colors yet
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
    # Recieves a list of powers for each scene, e.g. for 2 scenes
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

    Logger.debug(
      "#{device_to_string(state, nil)}: base #{inspect(base_power)} #{inspect(base_colors)}"
    )

    list_scenes =
      state.scenes
      |> Enum.sort_by(fn {_, scene} -> scene.priority end)
      |> Enum.map(fn {_, scene} -> scene end)

    colors =
      list_scenes
      |> Enum.map(fn scene -> scene.colors end)
      |> merge_colors(base_colors)

    power =
      list_scenes
      |> Enum.map(fn scene -> scene.power end)
      |> merge_power(base_power)

    Logger.debug("#{device_to_string(state, nil)}: GOT #{inspect(power)} #{inspect(colors)}")
    restore_device(state, {power, colors})
    state
  end

  @spec update_scene_state(State.t(), pid(), String.t(), integer(), list(HSBKA)) :: State.t()
  defp update_scene_state(state, pid, scene_name, power, hsbkas) do
    Logger.info("#{device_to_string(state, nil)}: update_scene_state #{scene_name}")
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

    scene = Map.fetch!(state.scenes, scene_name)

    if scene.task.pid == pid do
      scene = %SceneState{scene | colors: hsbkas, power: power}
      scenes = Map.put(state.scenes, scene_name, scene)
      state = %State{state | scenes: scenes}
      handle_update(state)
    else
      Logger.info("#{device_to_string(state, nil)}: update_scene_state #{scene_name} wrong pid")
      state
    end
  end

  # Add/remove scenes

  @spec scene_exists?(State.t(), String.t()) :: boolean()
  def scene_exists?(%State{} = state, scene_name) do
    Map.has_key?(state.scenes, scene_name)
  end

  @spec stop_scene(State.t(), String.t()) :: :ok
  def stop_scene(state, scene_name) do
    case Map.fetch(state.scenes, scene_name) do
      {:ok, scene} -> Task.shutdown(scene.task)
      :error -> nil
    end

    :ok
  end

  @spec add_scene(State.t(), String.t(), integer(), (() -> :ok)) :: State.t()
  defp add_scene(%State{} = state, scene_name, priority, function) do
    Logger.info("#{device_to_string(state, nil)}: add_scene #{scene_name}")
    already_exists = scene_exists?(state, scene_name)

    if already_exists do
      :ok = stop_scene(state, scene_name)
    end

    task = Task.async(function)

    scene = %SceneState{
      priority: priority,
      task: task
    }

    scenes = Map.put(state.scenes, scene_name, scene)
    %State{state | scenes: scenes}
  end

  @spec remove_scene(State.t(), String.t()) :: State.t()
  defp remove_scene(%State{} = state, scene_name) do
    Logger.info("remove_scene #{scene_name}")

    :ok = stop_scene(state, scene_name)
    scenes = Map.delete(state.scenes, scene_name)
    %State{state | scenes: scenes}
  end

  # @spec remove_all_scenes(State.t()) :: State.t()
  # defp remove_all_scenes(%State{} = state) do
  #   Enum.reduce(state.scenes, state, fn {scene_name, _}, state -> remove_scene(state, scene_name) end)
  # end

  @spec remove_all_scenes_with_priority(State.t(), integer) :: State.t()
  defp remove_all_scenes_with_priority(%State{} = state, priority) do
    Enum.reduce(state.scenes, state, fn
      {scene_name, %SceneState{priority: ^priority}}, state -> remove_scene(state, scene_name)
      {_, %SceneState{}}, state -> state
    end)
  end

  @spec keyword_list_to_map(values :: list) :: map
  defp keyword_list_to_map(values) do
    for {key, val} <- values, into: %{}, do: {key, val}
  end

  @spec handle_scene_has_died(State.t(), pid()) :: State.t()
  defp handle_scene_has_died(%State{} = state, pid) do
    Logger.info("#{device_to_string(state, nil)}: handle_scene_has_died #{inspect(pid)}")

    scenes =
      state.scenes
      |> Enum.reject(fn {_, scene} -> scene.task.pid == pid end)
      |> keyword_list_to_map()

    state = %State{
      state
      | scenes: scenes
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
  defp do_command_stop(state, command) do
    state =
      if command.stop_scenes == nil do
        state
      else
        Enum.reduce(command.stop_scenes, state, fn scene, state ->
          remove_scene(state, scene)
        end)
      end

    state =
      if command.stop_priorities == nil do
        state
      else
        Enum.reduce(command.stop_priorities, state, fn priority, state ->
          remove_all_scenes_with_priority(state, priority)
        end)
      end

    state
  end

  defp do_command(%State{} = state, %{action: "turn_off"} = command) do
    Logger.debug("#{device_to_string(state, nil)}: turn_off")
    number = get_number(state)
    priority = get_priority(command, 100)
    scene = command.scene

    # Ensure light is turned off even if it was previously on.
    %State{state | base_power: 0, base_colors: replicate(@black, number)}
    |> do_command_stop(command)
    |> remove_scene(scene)
    |> remove_all_scenes_with_priority(priority)
    |> publish_device_state()
    |> handle_update()
  end

  defp do_command(%State{} = state, %{action: "turn_on"} = command) do
    Logger.debug("#{device_to_string(state, nil)}: turn_on")
    number = get_number(state)
    priority = get_priority(command, 100)
    scene = command.scene

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
      GenServer.cast(pid, {:update, self(), scene, power, colors})
      :ok
    end

    state
    |> do_command_stop(command)
    |> remove_scene(scene)
    |> remove_all_scenes_with_priority(priority)
    |> add_scene(scene, priority, fn -> FixedColor.go(sender, 65535, colors) end)
    |> publish_device_state()
  end

  defp do_command(%State{} = state, %{action: "animate"} = command) do
    Logger.debug("#{device_to_string(state, nil)}: animate")
    pid = self()
    number = get_number(state)
    priority = get_priority(command, 100)
    scene = command.scene
    state = do_command_stop(state, command)

    case command.animation do
      nil ->
        state

      animation ->
        sender = fn power, hsbkas ->
          GenServer.cast(pid, {:update, self(), scene, power, hsbkas})
          :ok
        end

        state
        |> do_command_stop(command)
        |> remove_scene(scene)
        |> remove_all_scenes_with_priority(priority)
        |> add_scene(scene, priority, fn ->
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
  defp handle_command(%State{}, %{scene: nil} = command) do
    Logger.error("Cannot handle LIFX command #{inspect(command)} without scene")
  end

  defp handle_command(%State{} = state, command) do
    command = apply_scenes_to_command(command, state)
    do_command(state, command)
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

  def handle_cast({:update, pid, scene_name, power, hsbkas}, %State{} = state) do
    state = update_scene_state(state, pid, scene_name, power, hsbkas)
    {:noreply, state}
  end

  def handle_cast({:added, %Lifx.Device{}}, %State{} = state) do
    # Note device.label will not be set yet
    {:noreply, state}
  end

  def handle_cast({:updated, %Lifx.Device{}}, %State{} = state) do
    {:noreply, state}
  end

  def handle_cast({:deleted, %Lifx.Device{} = device}, %State{} = state) do
    if device.label == state.config.label do
      Logger.info("#{device_to_string(state, nil)}: got deleted #{inspect(device)}")
      publish_device_hard_off(state, nil)
    end

    {:noreply, state}
  end

  def handle_cast({:polled, %Lifx.Device{} = device}, %State{} = state) do
    state =
      if device.label == state.config.label do
        Logger.debug("#{device_to_string(state, nil)}: got polled")
        poll_device(state)
      else
        state
      end

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

  def handle_info({:DOWN, _ref, :process, pid, _reason}, %State{} = state) do
    new_state = handle_scene_has_died(state, pid)
    {:noreply, new_state}
  end

  def handle_info({_ref, _status}, state) do
    {:noreply, state}
  end
end
