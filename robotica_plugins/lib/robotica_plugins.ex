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

    def v(value), do: not is_nil(value)

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
        v(lights_action) -> "Lights #{lights_action}."
        v(music_stop) and music_stop -> "Music stop."
        v(music_playlist) -> "Music #{music_playlist}."
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
  end

  defmodule ScheduledTask do
    @type t :: %__MODULE__{
            locations: list(String.t()),
            devices: list(String.t()),
            action: Action.t(),
            id: String.t() | nil,
            mark: Mark.t() | nil,
            repeat_time: integer | nil,
            repeat_count: integer
          }
    @enforce_keys [:locations, :devices, :action, :mark, :repeat_time, :repeat_count]
    defstruct locations: [],
              devices: [],
              action: nil,
              id: nil,
              mark: nil,
              repeat_time: nil,
              repeat_count: 0

    defp div_rem(value, divider) do
      {div(value, divider), rem(value, divider)}
    end

    defp pad(number) do
      number
      |> Integer.to_string()
      |> String.pad_leading(2, "0")
    end

    defp duration_to_string(duration) do
      {total, seconds} = div_rem(duration, 60)
      {hours, minutes} = div_rem(total, 60)

      "#{pad(hours)}:#{pad(minutes)}:#{pad(seconds)}"
    end

    def task_to_text(%ScheduledTask{} = task) do
      list = []

      list =
        if task.repeat_count > 0 do
          ["(#{task.repeat_count}/#{duration_to_string(task.repeat_time)})" | list]
        else
          list
        end

      action_str = Action.action_to_text(task.action)
      list = [action_str | list]

      Enum.join(list, " ")
    end

    def to_task(%ScheduledTask{} = task) do
      %Task{locations: task.locations, devices: task.devices, action: task.action}
    end
  end

  defmodule ScheduledStep do
    @type t :: %__MODULE__{
            required_time: integer,
            latest_time: integer | nil,
            zero_time: boolean(),
            task: ScheduledTask.t()
          }
    @enforce_keys [:required_time, :latest_time, :task]
    defstruct required_time: nil,
              latest_time: nil,
              zero_time: false,
              task: nil
  end

  defmodule SingleStep do
    @type t :: %__MODULE__{
            required_time: %DateTime{},
            latest_time: %DateTime{},
            task: ScheduledTask.t()
          }
    @enforce_keys [:required_time, :latest_time, :task]
    defstruct required_time: nil, latest_time: nil, task: nil
  end

  defmodule MultiStep do
    @type t :: %__MODULE__{
            required_time: %DateTime{},
            latest_time: %DateTime{},
            tasks: list(ScheduledTask.t())
          }
    @enforce_keys [:required_time, :latest_time, :tasks]
    defstruct required_time: nil,
              latest_time: nil,
              tasks: []
  end
end
