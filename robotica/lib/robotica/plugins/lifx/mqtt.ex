defmodule Robotica.Plugins.Lifx.Mqtt do
  @moduledoc """
  LIFX Animation that displays a time dependant color
  """
  use GenServer
  require Logger

  alias Robotica.Devices.Lifx, as: RLifx
  alias Robotica.Devices.Lifx.HSBKA

  defmodule Options do
    @moduledoc """
    Options for Auto animation
    """
    @type t :: %__MODULE__{
            sender: RLifx.callback(),
            topic: String.t(),
            number: integer()
          }
    @enforce_keys [:sender, :topic, :number]
    defstruct @enforce_keys
  end

  defmodule State do
    @moduledoc false
    @type t :: %__MODULE__{
            options: Options.t()
          }
    @enforce_keys [:options]
    defstruct @enforce_keys
  end

  def start(%Options{} = options) do
    GenServer.start(__MODULE__, options)
  end

  @impl true
  @spec init(Robotica.Plugins.Lifx.Mqtt.Options.t()) ::
          {:ok, Robotica.Plugins.Lifx.Mqtt.State.t()}
  def init(%Options{} = options) do
    state = %State{
      options: options
    }

    MqttPotion.Multiplexer.subscribe_str(
      options.topic,
      :mqtt,
      self(),
      :json,
      :resend
    )

    {:ok, state}
  end

  @impl true
  def handle_cast(:stop, %State{} = state) do
    {:stop, :normal, state}
  end

  @impl true
  def handle_cast({:mqtt, _, :mqtt, json}, state) do
    options = state.options

    power =
      case json["power"] do
        "ON" -> 65_535
        "OFF" -> 0
        nil -> nil
      end

    colors =
      cond do
        json["colors"] != nil ->
          Enum.map(json["colors"], &json_color/1)

        json["color"] != nil ->
          color = json_color(json["color"])
          RLifx.replicate(color, options.number)

        true ->
          Logger.error("Cannot work out colors from #{inspect(json)}")
          []
      end

    state.options.sender.(power, colors)
    {:noreply, state}
  end

  @spec json_color(map()) :: HSBKA.t()
  defp json_color(json_color) do
    %HSBKA{
      hue: json_color["hue"] || 0,
      saturation: json_color["saturation"] || 0,
      brightness: json_color["brightness"] || 100,
      kelvin: json_color["kelvin"] || 3500,
      alpha: json_color["alpha"] || 100
    }
  end
end
