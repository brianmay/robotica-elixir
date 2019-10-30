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

  defp div_rem(value, divider) do
    {div(value, divider), rem(value, divider)}
  end

  defp pad(number, digits) do
    number
    |> Integer.to_string()
    |> String.pad_leading(digits, "0")
  end

  defp format_distance(value) do
    value = round(value)
    {km, m} = div_rem(value, 1000)
    "#{km},#{pad(m, 3)}m"
  end

  defp format_time_minutes(nil), do: nil

  defp format_time_minutes(value) do
    value = round(value)
    {hours, minutes} = div_rem(value, 60)
    "#{pad(hours, 2)}:#{pad(minutes, 2)}"
  end

  defp format_time_hours(nil), do: nil

  defp format_time_hours(value) do
    format_time_minutes(value * 60)
  end
end
