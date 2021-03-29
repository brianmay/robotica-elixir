defmodule RoboticaPlugins.Buttons do
  @doc """
  Functions to operate on buttons.
  """
  use RoboticaPlugins.EventBus

  defmodule Config do
    @type t :: %__MODULE__{
            name: String.t(),
            id: String.t(),
            location: String.t() | nil,
            device: String.t(),
            type: String.t(),
            action: String.t(),
            params: map()
          }
    defstruct [
      :name,
      :id,
      :location,
      :device,
      :type,
      :action,
      :params
    ]
  end

  @type state :: any()
  @type display_state :: :state_on | :state_off | :state_hard_off | :state_error | nil

  @callback get_initial_state(Config.t()) :: state
  @callback get_topics(Config.t()) :: list({list(String.t()), atom(), atom()})

  @callback process_message(Config.t(), atom(), any(), state) :: state
  @callback get_display_state(Config.t(), state) :: display_state
  @callback get_press_commands(Config.t(), state) :: list(RoboticaPlugins.Command.t())

  @spec get_button_controller(Config.t()) :: module()
  def get_button_controller(%Config{type: "light"}), do: RoboticaPlugins.Buttons.Light
  def get_button_controller(%Config{type: "music"}), do: RoboticaPlugins.Buttons.Music
  def get_button_controller(%Config{type: "hdmi"}), do: RoboticaPlugins.Buttons.HDMI
  def get_button_controller(%Config{type: "switch"}), do: RoboticaPlugins.Buttons.Switch

  @spec get_initial_state(Config.t()) :: state
  def get_initial_state(%Config{} = config) do
    controller = get_button_controller(config)
    controller.get_initial_state(config)
  end

  @spec get_topics(Config.t()) :: list({list(String.t()), atom(), atom()})
  def get_topics(%Config{} = config) do
    controller = get_button_controller(config)
    controller.get_topics(config)
  end

  @spec process_message(Config.t(), atom(), any(), state) :: state
  def process_message(%Config{} = config, label, data, state) do
    controller = get_button_controller(config)
    controller.process_message(config, label, data, state)
  end

  @spec get_display_state(Config.t(), state) :: display_state
  def get_display_state(%Config{} = config, state) do
    controller = get_button_controller(config)
    controller.get_display_state(config, state)
  end

  @spec get_press_commands(Config.t(), state) :: list(RoboticaPlugins.Command.t())
  def get_press_commands(%Config{} = config, state) do
    controller = get_button_controller(config)
    controller.get_press_commands(config, state)
  end

  @spec subscribe_topics(Config.t()) :: :ok
  def subscribe_topics(config) do
    config
    |> get_topics()
    |> Enum.each(fn {topic, format, label} ->
      RoboticaPlugins.EventBus.notify(:subscribe, %{
        topic: topic,
        label: {config.id, label},
        pid: self(),
        format: format,
        resend: :resend
      })
    end)
  end

  @spec unsubscribe_all() :: :ok
  def unsubscribe_all() do
    RoboticaPlugins.EventBus.notify(:unsubscribe_all, %{
      pid: self()
    })
  end

  @spec execute_press_commands(Config.t(), state) :: :ok
  def execute_press_commands(%Config{} = config, state) do
    commands = get_press_commands(config, state)

    Enum.each(commands, fn command ->
      RoboticaPlugins.EventBus.notify(:command, command)
    end)
  end
end
