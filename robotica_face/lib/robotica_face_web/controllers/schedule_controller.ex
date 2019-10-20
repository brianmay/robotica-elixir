defmodule RoboticaFaceWeb.ScheduleController do
  use RoboticaFaceWeb, :controller

  def upcoming_list(conn, _params) do
    render(conn, "schedule.html")
  end
end
