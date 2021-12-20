defmodule Robotica.Types do
  @moduledoc """
  Robotica Types
  """

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
            if_not: list(String.t()) | nil,
            replace: list(String.t()) | nil,
            day_type: String.t() | nil
          }
    @enforce_keys [:day_type]
    defstruct start: nil,
              stop: nil,
              date: nil,
              week_day: nil,
              day_of_week: nil,
              if: nil,
              if_not: nil,
              replace: nil,
              day_type: nil
  end
end
