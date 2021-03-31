defmodule RoboticaPlugins do
  defmodule Command do
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
    @type t :: %__MODULE__{
            locations: list(String.t()),
            devices: list(String.t()),
            command: map()
          }
    @enforce_keys [:locations, :devices, :command]
    defstruct locations: [], devices: [], command: nil

    def task_to_text(%Task{} = task, opts \\ []) do
      list = []

      action_str = Command.command_to_text(task.command)
      list = [action_str | list]

      list =
        case task.devices do
          [] -> ["Nowhere:" | list]
          devices -> [Enum.join(devices, ", ") <> ":" | list]
        end

      list =
        case opts[:include_locations] do
          true ->
            case task.locations do
              [] -> ["Nowhere:" | list]
              locations -> [Enum.join(locations, ", ") <> ":" | list]
            end

          _ ->
            list
        end

      Enum.join(list, " ")
    end
  end

  defmodule CommandTask do
    @type t :: %__MODULE__{
            location: String.t(),
            device: String.t(),
            command: map()
          }
    @enforce_keys [:location, :device, :command]
    defstruct location: [], device: [], command: {}
  end

  defmodule SourceStep do
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
