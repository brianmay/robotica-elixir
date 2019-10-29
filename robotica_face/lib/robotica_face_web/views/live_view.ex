defmodule RoboticaFaceWeb.LiveView do
  use RoboticaFaceWeb, :view

  @timezone Application.get_env(:robotica_plugins, :timezone)

  defp date_time_to_local(nil), do: nil

  defp date_time_to_local(dt) do
    dt
    |> Timex.parse!("{ISO:Extended}")
    |> Timex.Timezone.convert(@timezone)
    |> Timex.format!("%F %T", :strftime)
  end

  defp door_state(value) do
    case value do
      0 -> "Closed"
      1 -> "Open"
    end
  end
end
