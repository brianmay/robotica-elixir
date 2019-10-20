#
#  Created by Boyd Multerer on August 8, 2018.
#  Copyright © 2018 Kry10 Industries. All rights reserved.
#

defmodule Scenic.Clock.Digital do
  @moduledoc """
  A component that runs an digital clock.

  See the [Components](Scenic.Clock.Components.html#digital_clock/2) module for useage


  """
  use Scenic.Component, has_children: false

  alias Scenic.Graph
  alias Scenic.Primitive.Style.Theme
  import Scenic.Primitives, only: [{:text, 2}, {:text, 3}]

  # formats setup
  @default_format "%a %l:%M %p"

  @default_theme :dark

  # --------------------------------------------------------
  @doc false
  def verify(nil), do: {:ok, nil}
  def verify(_), do: :invalid_data

  # --------------------------------------------------------
  @doc false
  def init(_, opts) do
    styles = opts[:styles]

    # theme is passed in as an inherited style
    theme =
      (styles[:theme] || Theme.preset(@default_theme))
      |> Theme.normalize()

    format =
      case styles[:format] do
        nil -> @default_format
        format -> format
      end

    timezone = styles[:timezone]

    # set up the requested graph
    graph =
      Graph.build(styles: styles)
      |> text("", id: :time, fill: theme.text)

    {state, graph} =
      %{
        graph: graph,
        timezone: timezone,
        format: format,
        timer: nil,
        last: nil,
        seconds: !!styles[:seconds]
      }
      # start up the graph
      |> update_time()

    # send a message to self to start the clock a fraction of a second
    # into the future to hopefully line it up closer to when the seconds
    # actually are. Note that I want it to arrive just slightly after
    # the one second mark, which is way better than just slighty before.
    # avoid trunc errors and such that way even if it means the second
    # timer is one millisecond behind the actual time.
    {microseconds, _} = Time.utc_now().microsecond
    Process.send_after(self(), :start_clock, 1001 - trunc(microseconds / 1000))

    {:ok, state, push: graph}
  end

  # --------------------------------------------------------
  @doc false
  # should be shortly after the actual one-second mark
  def handle_info(:start_clock, state) do
    # start the timer on a one-second interval
    {:ok, timer} = :timer.send_interval(1000, :tick_tock)

    # update the clock
    {state, graph} = update_time(state)
    {:noreply, %{state | timer: timer}, push: graph}
  end

  # --------------------------------------------------------
  def handle_info(:tick_tock, state) do
    {state, graph} = update_time(state)
    {:noreply, state, push: graph}
  end

  # --------------------------------------------------------
  defp update_time(
         %{
           format: format,
           timezone: timezone,
           graph: graph,
           last: last
         } = state
       ) do
    {:ok, time} = Timex.now(timezone) |> Timex.format(format, :strftime)

    case time != last do
      true ->
        graph = Graph.modify(graph, :time, &text(&1, time))
        {%{state | last: time}, graph}

      _ ->
        {state, nil}
    end
  end
end
