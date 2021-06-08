defmodule RoboticaPlugins do
  @moduledoc """
  Common stuff
  """
  defmodule Command do
    @moduledoc """
    Private stuff for common stuff
    """

    defp v(value), do: not is_nil(value)

    defp add_list_if_cond(list, true, item), do: [item | list]
    defp add_list_if_cond(list, false, _), do: list

    defp add_list_if_empty([], item), do: [item]
    defp add_list_if_empty(list, _), do: list

    def command_to_text(%{"type" => "audio"} = command) do
      message_text = get_in(command, ["message", "text"])
      music_playlist = get_in(command, ["music", "play_list"])
      music_stop = get_in(command, ["music", "stop"])

      message_volume = get_in(command, ["volume", "message"])
      music_volume = get_in(command, ["volume", "music"])

      []
      |> add_list_if_cond(v(message_volume), "Message #{message_volume}%")
      |> add_list_if_cond(v(message_text), "Message #{message_text}")
      |> add_list_if_cond(v(music_stop) and music_stop, "Music Stop")
      |> add_list_if_cond(v(music_volume), "Music #{music_volume}%")
      |> add_list_if_cond(v(music_playlist), "Music #{music_playlist}")
      |> add_list_if_empty("N/A")
      |> Enum.join(", ")
    end

    def command_to_text(%{"type" => "light"} = command) do
      lights_action = get_in(command, ["action"])
      lights_scene = get_in(command, ["scene"])

      []
      |> add_list_if_cond(v(lights_action), "Lights #{lights_action} #{lights_scene}")
      |> add_list_if_cond(v(lights_scene), "Lights #{lights_scene}")
      |> add_list_if_empty("N/A")
      |> Enum.join(", ")
    end

    def command_to_text(%{"type" => "device"} = command) do
      device_action = get_in(command, ["action"])

      []
      |> add_list_if_cond(v(device_action), "Device #{device_action}")
      |> add_list_if_empty("N/A")
      |> Enum.join(", ")
    end

    def command_to_text(%{"type" => "hdmi"} = command) do
      hdmi_source = get_in(command, ["source"])

      []
      |> add_list_if_cond(v(hdmi_source), "HDMI #{hdmi_source}")
      |> add_list_if_empty("N/A")
      |> Enum.join(", ")
    end

    def command_to_text(command) do
      inspect(command)
    end

    def command_to_message(%{type: "audio"} = action) do
      get_in(action.message, [:text])
    end

    def command_to_message(%{}) do
      ""
    end
  end

  defmodule Task do
    @moduledoc """
    Defines a list of locations, list of devices, and a command to execute
    """
    @type t :: %__MODULE__{
            locations: list(String.t()),
            devices: list(String.t()),
            command: map()
          }
    @enforce_keys [:locations, :devices, :command]
    defstruct locations: [], devices: [], command: nil

    @spec location_device_to_text(String.t(), String.t(), keyword()) :: String.t()
    defp location_device_to_text(location, device, opts) do
      case opts[:include_locations] do
        true ->
          "/#{location}/#{device}"

        _ ->
          "#{device}"
      end
    end

    @spec task_to_text(RoboticaPlugins.Task.t(), keyword()) :: String.t()
    def task_to_text(%Task{} = task, opts \\ []) do
      list = []

      action_str = Command.command_to_text(task.command)
      list = [action_str | list]

      location_list =
        Enum.reduce(task.locations, [], fn location, list ->
          Enum.reduce(task.devices, list, fn device, list ->
            [location_device_to_text(location, device, opts) | list]
          end)
        end)

      list =
        case location_list do
          [] -> ["Nowhere:" | list]
          location_list -> [Enum.join(location_list, ", ") <> ":" | list]
        end

      Enum.join(list, " ")
    end
  end

  defmodule CommandTask do
    @moduledoc """
    Defines a location, device, and a command to execute
    """
    @type t :: %__MODULE__{
            location: String.t(),
            device: String.t(),
            command: map()
          }
    @enforce_keys [:location, :device, :command]
    defstruct location: [], device: [], command: {}
  end

  defmodule SourceStep do
    @moduledoc """
    Defines a step in the source schedule
    """
    @type t :: %__MODULE__{
            required_time: integer,
            latest_time: integer | nil,
            zero_time: boolean(),
            tasks: list(Task.t()),
            id: String.t() | nil,
            repeat_time: integer | nil,
            repeat_count: integer,
            repeat_number: integer | nil,
            options: list(String.t()) | nil
          }
    @enforce_keys [:required_time, :latest_time, :tasks]
    defstruct id: nil,
              required_time: nil,
              latest_time: nil,
              zero_time: false,
              tasks: [],
              repeat_time: nil,
              repeat_count: 0,
              repeat_number: nil,
              options: []
  end

  defmodule ScheduledStep do
    @moduledoc """
    Defines a step in the scheduler process
    """
    @type t :: %__MODULE__{
            required_time: %DateTime{},
            latest_time: %DateTime{},
            tasks: list(CommandTask.t()),
            id: String.t(),
            mark: :done | :cancelled | nil,
            repeat_number: integer | nil
          }
    @enforce_keys [:required_time, :latest_time, :tasks, :id]
    defstruct required_time: nil,
              latest_time: nil,
              tasks: [],
              id: nil,
              mark: nil,
              repeat_number: 0

    def step_to_text(%ScheduledStep{} = step, opts \\ []) do
      step.tasks
      |> Enum.map(fn task -> Task.task_to_text(task, opts) end)
      |> Enum.map(fn text ->
        case step.repeat_number do
          nil -> text
          repeat_number -> "#{text}. (#{repeat_number})"
        end
      end)
    end

    def step_to_locations(%ScheduledStep{} = step) do
      step.tasks
      |> Enum.map(fn task -> task.locations end)
      |> List.flatten()
      |> MapSet.new()
    end
  end
end
