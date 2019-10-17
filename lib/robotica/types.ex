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
            action: RoboticaPlugins.Action.t(),
            id: String.t() | nil,
            mark: Mark.t() | nil
          }
    @enforce_keys [:locations, :action, :mark]
    defstruct locations: [], action: nil, id: nil, mark: nil
  end

end
