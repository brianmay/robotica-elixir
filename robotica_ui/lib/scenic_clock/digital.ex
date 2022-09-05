#
#  Created by Boyd Multerer on August 8, 2018.
#  Copyright © 2018 Kry10 Industries. All rights reserved.
#

defmodule Scenic.Clock.Digital do
  @moduledoc """
  A component that runs an digital clock.
  """
  use Scenic.Component, has_children: false

  alias Scenic.Graph
  alias Scenic.Primitive.Style.Theme
  import Scenic.Primitives, only: [{:text, 2}, {:text, 3}]

  @default_theme :dark

  # --------------------------------------------------------
  @doc false
  def validate(nil), do: {:ok, nil}
  def validate(_), do: :invalid_data

  # --------------------------------------------------------
  @doc false
  def init(scene, _, opts) do
    # theme is passed in as an inherited style
    theme =
      (opts[:theme] || Theme.preset(@default_theme))
      |> Theme.normalize()

    timezone = opts[:timezone]

    # set up the requested graph
    graph =
      Graph.build()
      |> text("", id: :date, fill: theme.text, font_size: 32)
      |> text("", id: :time, fill: theme.text, translate: {0, 64}, font_size: 32)

    scene =
      scene
      |> assign(
        graph: graph,
        timezone: timezone,
        timer: nil,
        last: nil,
        seconds: !!opts[:seconds]
      )
      |> update_time()

    # send a message to self to start the clock a fraction of a second
    # into the future to hopefully line it up closer to when the seconds
    # actually are. Note that I want it to arrive just slightly after
    # the one second mark, which is way better than just slighty before.
    # avoid trunc errors and such that way even if it means the second
    # timer is one millisecond behind the actual time.
    {microseconds, _} = Time.utc_now().microsecond
    Process.send_after(self(), :start_clock, 1001 - trunc(microseconds / 1000))

    {:ok, scene}
  end

  # --------------------------------------------------------
  # should be shortly after the actual one-second mark
  @doc false
  def handle_info(:start_clock, scene) do
    # start the timer on a one-second interval
    {:ok, timer} = :timer.send_interval(1000, :tick_tock)

    # update the clock
    scene =
      scene
      |> update_time()
      |> assign(timer: timer)

    {:noreply, scene}
  end

  # --------------------------------------------------------
  def handle_info(:tick_tock, scene) do
    scene = update_time(scene)
    {:noreply, scene}
  end

  # --------------------------------------------------------
  defp update_time(scene) do
    {:ok, time} = DateTime.now(scene.assigns.timezone)

    case time != scene.assigns.last do
      true ->
        graph = scene.assigns.graph

        {:ok, date_str} = time |> Timex.format("%F %A", :strftime)
        graph = Graph.modify(graph, :date, &text(&1, date_str))

        {:ok, time_str} = time |> Timex.format("%k:%M:%S %z", :strftime)
        graph = Graph.modify(graph, :time, &text(&1, time_str))

        scene
        |> assign(last: time, graph: graph)
        |> push_graph(graph)

      _ ->
        scene
    end
  end
end
