defmodule Robotica.Types do
  defmodule Classification do
    @enforce_keys [:day_type]
    defstruct start: nil,
              stop: nil,
              date: nil,
              week_day: nil,
              day_of_week: nil,
              exclude: nil,
              day_type: nil
  end

  defmodule ScheduledTask do
    @type t :: %__MODULE__{
            locations: list(String.t()),
            action: Robotica.Types.Action.t(),
            frequency: :daily | :weekly | nil,
            id: String.t() | nil,
            mark: Mark.t() | nil
          }
    @enforce_keys [:locations, :action, :frequency, :mark]
    defstruct locations: [], action: nil, frequency: nil, id: nil, mark: nil
  end

  defmodule Step do
    @type t :: %__MODULE__{
            required_time: integer,
            latest_time: integer | nil,
            zero_time: boolean(),
            task: ScheduledTask.t()
          }
    @enforce_keys [:required_time, :latest_time, :task]
    defstruct required_time: nil, latest_time: nil, zero_time: false, task: nil
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
