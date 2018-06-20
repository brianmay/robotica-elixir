defmodule Robotica.Plugins.Audio do
  use GenServer

  defmodule State do
    @type t :: %__MODULE__{
            commands: %{required(String.t()) => String.t()},
            sounds: %{required(String.t()) => String.t()},
            location: String.t()
          }
    @enforce_keys [:location]
    defstruct commands: %{},
              sounds: %{},
              location: nil
  end

  ## Client API

  @spec start_link(config: State.t()) :: {:ok, pid} | {:error, String.t()}
  def start_link(config) do
    with {:ok, pid} <- GenServer.start_link(__MODULE__, config, []) do
      Robotica.Registry.add(Robotica.Registry, config.location, pid)
      {:ok, pid}
    else
      err -> err
    end
  end

  ## Server Callbacks

  def init(opts) do
    {:ok, opts}
  end

  @spec replace_values(String.t(), %{required(String.t()) => String.t()}) :: String.t()
  defp replace_values(string, values) do
    Regex.replace(~r/{([a-z]+)?}/, string, fn _, match ->
      Map.fetch!(values, match)
    end)
  end

  defp run_commands(state, [cmd | tail], values) do
    [cmd | args] = cmd
    args = Enum.map(args, &replace_values(&1, values))
    IO.puts(cmd <> inspect(args))

    case System.cmd(cmd, args) do
      {_, 0} ->
        IO.puts("result no error")
        run_commands(state, tail, values)

      {_, rc} ->
        IO.puts("result " <> inspect(rc))
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
    0 = run(state, "sayabc", text: text)
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

  defp do_execute(state, action) do
    paused =
      if Map.has_key?(action, "music") do
        music_stop(state)
        false
      else
        music_paused?(state)
      end

    if Map.has_key?(action, "timer_status") do
      play_sound(state, "beep")
    end

    if Map.has_key?(action, "sound") do
      sound = get_in(action, ["sound"])
      play_sound(state, sound)
    end

    if Map.has_key?(action, "timer_status") do
      time_left = get_in(action, ["timer_status", "time_left"])
      play_sound(state, "beep")

      if time_left > 0 and rem(time_left, 5) == 0 do
        say(state, "{time_left} minutes")
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
    do_execute(state, action)
    {:noreply, state}
  end
end
