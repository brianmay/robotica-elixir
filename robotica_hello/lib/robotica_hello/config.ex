defmodule RoboticaHello.Config do
  @moduledoc """
  Configuration for RoboticaHello
  """

  defp instance do
    %{
      name: {:string, true},
      url: {:string, true}
    }
  end

  defp config_schema do
    %{
      instances: {{:list, instance()}, true}
    }
  end

  def configuration do
    filename = Application.get_env(:robotica_hello, :config_file)
    {:ok, data} = RoboticaPlugins.Validation.load_and_validate(filename, config_schema())
    data
  end
end
