defmodule RoboticaHelloWeb.LayoutView do
  use RoboticaHelloWeb, :view

  def active_class(active, active), do: "active"
  def active_class(_, _), do: ""
end
