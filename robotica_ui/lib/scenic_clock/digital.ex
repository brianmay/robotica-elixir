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

    timezone = styles[:timezone]

    # set up the requested graph
    graph =
      Graph.build(styles: styles)
      |> text("", id: :date, fill: theme.text, font_size: 32)
      |> text("", id: :time, fill: theme.text, translate: {0, 64}, font_size: 32)

    {state, graph} =
      %{
        graph: graph,
        timezone: timezone,
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
           timezone: timezone,
           graph: graph,
           last: last
         } = state
       ) do
    {:ok, time} = DateTime.now(timezone)

    case time != last do
      true ->
        {:ok, date_str} = time |> Timex.format("%F %A", :strftime)
        graph = Graph.modify(graph, :date, &text(&1, date_str))

        {:ok, time_str} = time |> Timex.format("%k:%M:%S %z", :strftime)
        graph = Graph.modify(graph, :time, &text(&1, time_str))

        {%{state | last: time}, graph}

      _ ->
        {state, nil}
    end
  end
end
