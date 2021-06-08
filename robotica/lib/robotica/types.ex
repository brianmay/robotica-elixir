defmodule Robotica.Types do
  @moduledoc """
  Robotica Types
  """

  defmodule Classification do
    @moduledoc """
    A classification entry
    """

    @enforce_keys [:day_type]
    defstruct start: nil,
              stop: nil,
              date: nil,
              week_day: nil,
              day_of_week: nil,
              exclude: nil,
              day_type: nil
  end
end
