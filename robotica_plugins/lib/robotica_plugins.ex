defmodule RoboticaPlugins do
  alias RoboticaPlugins.Mark

  defmodule Action do
    @type t :: %__MODULE__{
            message: map() | nil,
            lights: map() | nil,
            sound: map() | nil,
            music: map() | nil,
            hdmi: map() | nil
          }
    defstruct message: nil,
              lights: nil,
              sound: nil,
              music: nil,
              hdmi: nil

    defp v(value), do: not is_nil(value)

    def action_to_text(%Action{} = action) do
      message = action.message
      lights = action.lights
      music = action.music

      message_text = get_in(message, [:text])
      lights_action = get_in(lights, [:action])
      music_playlist = get_in(music, [:play_list])
      music_stop = get_in(music, [:stop])

      cond do
        v(message_text) -> message_text
        v(lights_action) -> "Lights #{lights_action}"
        v(music_stop) and music_stop -> "Music stop"
        v(music_playlist) -> "Music #{music_playlist}"
        true -> "N/A"
      end
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
            mark: Mark.t() | nil,
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
