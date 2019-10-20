defmodule RoboticaPlugins do
  defmodule Action do
    @type t :: %__MODULE__{
            message: map() | nil,
            lights: map() | nil,
            sound: map() | nil,
            music: map() | nil
          }
    defstruct message: nil,
              lights: nil,
              sound: nil,
              music: nil

    def v(value), do: not is_nil(value)

    def action_to_msg(%Action{} = action) do
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
        v(music_stop) and music_stop -> "Music stop."
        v(music_playlist) -> "Music #{music_playlist}."
        true -> "N/A"
      end
    end
  end

  defmodule Task do
    @type t :: %__MODULE__{
            locations: list(String.t()),
            action: Robotica.Types.Action.t()
          }
    @enforce_keys [:locations, :action]
    defstruct locations: [], action: nil
  end

  defmodule Mark do
    @type t :: %__MODULE__{
            id: String.t(),
            status: :done | :cancelled,
            start_time: %DateTime{},
            stop_time: %DateTime{}
          }
    @enforce_keys [:id, :status, :start_time, :stop_time]
    defstruct id: nil,
              status: nil,
              start_time: nil,
              stop_time: nil
  end

  defmodule ScheduledTask do
    @type t :: %__MODULE__{
            locations: list(String.t()),
            action: Action.t(),
            id: String.t() | nil,
            mark: Mark.t() | nil,
            repeat_time: integer | nil,
            repeat_count: integer
          }
    @enforce_keys [:locations, :action, :mark, :repeat_time, :repeat_count]
    defstruct locations: [], action: nil, id: nil, mark: nil, repeat_time: nil, repeat_count: 0

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

    def task_to_msg(%ScheduledTask{} = task) do
      action_str = Action.action_to_msg(task.action)

      if task.repeat_count > 0 do
        "#{action_str} (#{task.repeat_count}/#{duration_to_string(task.repeat_time)})"
      else
        action_str
      end
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
