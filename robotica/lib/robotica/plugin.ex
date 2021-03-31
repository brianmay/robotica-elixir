defmodule Robotica.Plugin do
  require Logger

  @type t :: %__MODULE__{
          module: atom,
          location: String.t(),
          device: String.t(),
          config: map
        }
  @enforce_keys [:module, :location, :device, :config]
  defstruct module: nil, location: nil, device: nil, config: nil

  @callback config_schema :: map()

  defmacro __using__(_opts) do
    quote do
      @behaviour Robotica.Plugin
      import Robotica.Plugins.Private

      @spec start_link(plugin :: Robotica.Plugin.t()) ::
              {:ok, pid} | {:error, String.t()}
      def start_link(plugin) do
        with {:ok, pid} <- GenServer.start_link(__MODULE__, plugin, []) do
          Robotica.PluginRegistry.add(plugin.location, plugin.device, pid)

          RoboticaPlugins.Subscriptions.subscribe(
            ["command", plugin.location, plugin.device],
            :command,
            pid,
            :json,
            :no_resend
          )

          {:ok, pid}
        else
          err -> err
        end
      end
    end
  end
end
