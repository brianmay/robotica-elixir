defmodule Robotica.Plugin do
  @moduledoc """
  Common stuff for plugins
  """

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
        case GenServer.start_link(__MODULE__, plugin, []) do
          {:ok, pid} ->
            Robotica.PluginRegistry.add(plugin.location, plugin.device, pid)

            RoboticaCommon.Subscriptions.subscribe(
              ["command", plugin.location, plugin.device],
              :command,
              pid,
              :json,
              :no_resend
            )

            {:ok, pid}

          err ->
            err
        end
      end
    end
  end
end
