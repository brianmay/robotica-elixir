defmodule RoboticaFaceWeb.LayoutView do
  use RoboticaFaceWeb, :view

  def active_class(active, active), do: "active"
  def active_class(_, _), do: ""
end
