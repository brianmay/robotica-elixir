defmodule Robotica.Plugins.Audio do
  use GenServer
  use Robotica.Plugins.Plugin
  require Logger

  defmodule State do
    @type t :: %__MODULE__{
            commands: %{required(String.t()) => String.t()},
            sounds: %{required(String.t()) => String.t()}
          }
    defstruct commands: %{},
              sounds: %{}
  end

  ## Server Callbacks

  def init(config) do
    {:ok, config}
  end

  @spec replace_values(String.t(), %{required(String.t()) => String.t()}) :: String.t()
  defp replace_values(string, values) do
    Regex.replace(~r/{([a-z_]+)?}/, string, fn _, match ->
      Map.fetch!(values, match)
    end)
  end

  defp run_commands(state, [cmd | tail], values) do
    [cmd | args] = cmd
    args = Enum.map(args, &replace_values(&1, values))
    Logger.debug(cmd <> inspect(args))

    case System.cmd(cmd, args) do
      {_, 0} ->
        Logger.debug("result no error")
        run_commands(state, tail, values)

      {_, rc} ->
        Logger.debug("result " <> inspect(rc))
        rc
    end
  end

  defp run_commands(_state, [], _values) do
    0
  end

  defp run(state, cmd, values) do
    values = for {key, val} <- values, into: %{}, do: {Atom.to_string(key), val}

    cmds = Map.fetch!(state.commands, cmd)
    run_commands(state, cmds, values)
  end

  defp play_sound(state, sound) do
    sound_file = Map.fetch!(state.sounds, sound)
    0 = run(state, "play", file: sound_file)
  end

  defp say(state, text) do
    play_sound(state, "prefix")
    0 = run(state, "say", text: text)
    play_sound(state, "repeat")
    0 = run(state, "say", text: text)
    play_sound(state, "postfix")
    nil
  end

  defp music_paused?(state) do
    case run(state, "music_pause", []) do
      0 -> true
      _ -> false
    end
  end

  defp music_resume(state) do
    0 = run(state, "music_resume", [])
  end

  defp music_play(state, play_list) do
    0 = run(state, "music_play", play_list: play_list)
  end

  defp music_stop(state) do
    0 = run(state, "music_stop", [])
  end

  @spec handle_execute(state :: State.t(), action :: Robotica.Executor.Action.t()) :: nil
  defp handle_execute(state, action) do
    paused = music_paused?(state)

    if Map.has_key?(action, "timer_status") do
      play_sound(state, "beep")
    end

    if Map.has_key?(action, "sound") do
      sound = get_in(action, ["sound"])
      play_sound(state, sound)
    end

    if Map.has_key?(action, "timer_status") do
      time_left = get_in(action, ["timer_status", "time_left"])
      if time_left > 0 and rem(time_left, 5) == 0 do
        say(state, "#{time_left} minutes")
      end
    end

    if Map.has_key?(action, "timer_cancel") do
      play_sound(state, "cancelled")
      say(state, "timer cancelled")
    end

    if Map.has_key?(action, "message") do
      text = get_in(action, ["message", "text"])
      say(state, text)
    end

    cond do
      Map.has_key?(action, "music") ->
        play_list = get_in(action, ["music", "play_list"])
        music_play(state, play_list)

      paused ->
        music_resume(state)

      true ->
        nil
    end
  end

  def handle_call({:wait}, _from, state) do
    {:reply, nil, state}
  end

  def handle_cast({:execute, action}, state) do
    handle_execute(state, action)
    {:noreply, state}
  end
end
