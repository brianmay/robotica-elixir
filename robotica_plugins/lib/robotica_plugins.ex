defmodule RoboticaPlugins do
  defmodule Action do
    @type t :: %__MODULE__{
            message: map() | nil,
            lights: map() | nil,
            sound: map() | nil,
            music: map() | nil,
            hdmi: map() | nil,
            device: map() | nil
          }
    defstruct message: nil,
              lights: nil,
              sound: nil,
              music: nil,
              hdmi: nil,
              device: nil

    defp v(value), do: not is_nil(value)

    defp add_list_if_cond(list, :true, item), do: [item | list]
    defp add_list_if_cond(list, :false, _), do: list

    defp add_list_if_empty([], item), do: [item]
    defp add_list_if_empty(list, _), do: list

    def action_to_text(%Action{} = action) do
      message_text = get_in(action.message, [:text])
      lights_action = get_in(action.lights, [:action])
      device_action = get_in(action.device, [:action])
      hdmi_source = get_in(action.hdmi, [:source])
      music_playlist = get_in(action.music, [:play_list])
      music_stop = get_in(action.music, [:stop])
      music_volume = get_in(action.music, [:volume])

      []
      |> add_list_if_cond(v(message_text), "Say #{message_text}")
      |> add_list_if_cond(v(lights_action), "Lights #{lights_action}")
      |> add_list_if_cond(v(device_action), "Device #{device_action}")
      |> add_list_if_cond(v(hdmi_source), "HDMI #{hdmi_source}")
      |> add_list_if_cond(v(music_stop) and music_stop, "Music Stop")
      |> add_list_if_cond(v(music_playlist), "Music #{music_playlist}")
      |> add_list_if_cond(v(music_volume), "Volume #{music_volume}%")
      |> add_list_if_empty("N/A")
      |> Enum.join(",")
    end

    def action_to_message(%Action{} = action) do
      get_in(action.message, [:text])
    end
  end

  defmodule Task do
    @type t :: %__MODULE__{
            locations: list(String.t()),
            devices: list(String.t()),
            action: Action.t()
          }
    @enforce_keys [:locations, :devices, :action]
    defstruct locations: [], devices: [], action: nil

    def task_to_text(%Task{} = task) do
      list = []

      action_str = Action.action_to_text(task.action)
      list = [action_str | list]

      list =
        case task.devices do
          nil -> list
          [] -> ["Nowhere:" | list]
          devices -> [Enum.join(devices, ",") <> ":" | list]
        end

      Enum.join(list, " ")
    end
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
            tasks: list(Task.t()),
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

    def step_to_text(%ScheduledStep{} = step) do
      text =
        step.tasks
        |> Enum.map(fn task -> Task.task_to_text(task) end)
        |> Enum.join(", ")

      if not is_nil(step.repeat_number) do
        "#{text}. (#{step.repeat_number})"
      else
        "#{text}."
      end
    end

    def step_to_locations(%ScheduledStep{} = step) do
      step.tasks
      |> Enum.map(fn task -> task.locations end)
      |> List.flatten()
      |> MapSet.new()
    end
  end
end
