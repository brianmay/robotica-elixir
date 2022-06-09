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
