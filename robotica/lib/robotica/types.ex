defmodule Robotica.Types do
  @moduledoc """
  Robotica Types
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
    @derive Jason.Encoder
    @type t :: %__MODULE__{
            locations: list(String.t()) | nil,
            devices: list(String.t()) | nil,
            topics: list(String.t()) | nil,
            payload_json: map()
          }
    @enforce_keys [:locations, :devices, :topics, :payload_json]
    defstruct locations: [], devices: [], topics: [], payload_json: nil

    @spec normalize(Robotica.Types.Task.t()) :: Robotica.Types.Task.t()
    def normalize(%Task{} = task) do
      topics = task.topics || []
      locations = task.locations || []
      devices = task.devices || []

      topics_converted =
        Enum.map(locations, fn location ->
          Enum.map(devices, fn device -> "command/#{location}/#{device}" end)
        end)
        |> List.flatten()

      %{task | topics: topics ++ topics_converted}
    end

    @spec topic_to_text(String.t(), keyword()) :: String.t()
    defp topic_to_text(topic, opts) do
      case opts[:include_locations] do
        true ->
          topic

        _ ->
          String.split(topic, "/") |> List.last("nil")
      end
    end

    @spec task_to_text(Robotica.Types.Task.t(), keyword()) :: String.t()
    def task_to_text(%Task{} = task, opts \\ []) do
      list = []

      action_str = Command.command_to_text(task.payload_json)
      list = [action_str | list]

      topic_list =
        Enum.map(task.topics, fn topic ->
          topic_to_text(topic, opts)
        end)

      list =
        case topic_list do
          [] -> ["Nowhere:" | list]
          topic_list -> [Enum.join(topic_list, ", ") <> ":" | list]
        end

      Enum.join(list, " ")
    end
  end

  defmodule CommandTask do
    @moduledoc """
    Defines a location, device, and a command to execute
    """
    @type t :: %__MODULE__{
            topic: String.t(),
            payload_json: map()
          }
    @enforce_keys [:topic, :payload_json]
    defstruct [:topic, :payload_json]
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
            if: list(String.t()) | nil,
            classifications: list(String.t()) | nil,
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
              if: nil,
              classifications: [],
              options: []
  end

  defmodule ScheduledStep do
    @moduledoc """
    Defines a step in the scheduler process
    """
    @derive Jason.Encoder
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

  defmodule Classification do
    @moduledoc """
    A classification entry
    """

    @type t :: %__MODULE__{
            start: Date.t() | nil,
            stop: Date.t() | nil,
            date: Date.t() | nil,
            week_day: boolean() | nil,
            day_of_week: String.t() | nil,
            if: list(String.t()) | nil,
            if_set: list(String.t()) | nil,
            if_not_set: list(String.t()) | nil,
            add: list(String.t()) | nil,
            delete: list(String.t()) | nil
          }
    defstruct start: nil,
              stop: nil,
              date: nil,
              week_day: nil,
              day_of_week: nil,
              if: nil,
              if_set: nil,
              if_not_set: nil,
              add: nil,
              delete: nil
  end
end
