defmodule RoboticaFaceWeb.PageControllerTest do
  use RoboticaFaceWeb.ConnCase

  test "GET /", %{conn: conn} do
    conn = get(conn, "/")
    assert html_response(conn, 200) =~ "RoboticaFace · Phoenix Framework"
  end
end
