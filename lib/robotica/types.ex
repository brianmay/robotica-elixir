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

  defmodule Step do
    @type t :: %__MODULE__{
            required_time: integer,
            latest_time: integer | nil,
            zero_time: boolean(),
            task: Robotica.Executor.Task.t()
          }
    @enforce_keys [:required_time, :latest_time, :task]
    defstruct required_time: nil, latest_time: nil, zero_time: false, task: nil
  end

  defmodule MultiStep do
    @type t :: %__MODULE__{
            required_time: %DateTime{},
            latest_time: %DateTime{},
            tasks: list(Robotica.Executor.Task.t())
          }
    @enforce_keys [:required_time, :latest_time, :tasks]
    defstruct required_time: nil,
              latest_time: nil,
              tasks: []
  end
end
