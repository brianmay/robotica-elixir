defmodule Robotica.Plugins.Audio do
  use GenServer
  use Robotica.Plugin
  require Logger

  import Robotica.Types
  alias RoboticaPlugins.String

  defmodule Commands do
    @enforce_keys [
      :init,
      :volume,
      :play,
      :say,
      :music_play,
      :music_stop,
      :music_pause,
      :music_resume
    ]
    defstruct init: nil,
              volume: nil,
              play: nil,
              say: nil,
              music_play: nil,
              music_stop: nil,
              music_pause: nil,
              music_resume: nil
  end

  defmodule Config do
    @type t :: %__MODULE__{
            commands: Commands.t(),
            sounds: %{required(String.t()) => String.t()},
            volumes: %{required(atom()) => String.t()}
          }
    @enforce_keys [:commands, :sounds, :volumes]
    defstruct commands: %Commands{
                init: nil,
                volume: nil,
                play: nil,
                say: nil,
                music_play: nil,
                music_stop: nil,
                music_pause: nil,
                music_resume: nil
              },
              sounds: %{},
              volumes: %{}
  end

  ## Server Callbacks

  def init(plugin) do
    run(plugin.config, :init, [])
    set_volume(plugin.config, plugin.config.volumes.music)
    {:ok, plugin.config}
  end

  defp command_list do
    {:list, {:list, :string}}
  end

  defp commands do
    %{
      struct_type: Commands,
      init: {command_list(), true},
      volume: {command_list(), true},
      music_pause: {command_list(), true},
      music_play: {command_list(), true},
      music_resume: {command_list(), true},
      music_stop: {command_list(), true},
      play: {command_list(), true},
      say: {command_list(), true}
    }
  end

  defp sounds do
    %{
      "beep" => {:string, true},
      "postfix" => {:string, true},
      "prefix" => {:string, true},
      "repeat" => {:string, true}
    }
  end

  defp volumes do
    %{
      say: {:integer, true},
      music: {:integer, true}
    }
  end

  def config_schema do
    %{
      struct_type: Robotica.Plugins.Audio.Config,
      commands: {commands(), true},
      sounds: {sounds(), true},
      volumes: {volumes(), true}
    }
  end

  defp run_commands(state, [cmd | tail], values, on_nonzero) do
    [cmd | args] = cmd
    args = Enum.map(args, &String.solve_string_combined(&1, values))

    {args, errors} =
      Enum.split_with(args, fn
        {:ok, _} -> true
        {:error, _} -> false
      end)

    errors = Enum.map(errors, fn {:error, msg} -> msg end)
    args = Enum.map(args, fn {:ok, msg} -> msg end)

    case errors do
      [] ->
        string = "#{cmd} #{Enum.join(args, " ")}"
        Logger.debug("Running '#{string}'.")

        {_output, rc} = System.cmd(cmd, args)

        case {rc, on_nonzero} do
          {0, _} ->
            Logger.info("result 0 from '#{string}'.")
            run_commands(state, tail, values, on_nonzero)

          {rc, :error} ->
            Logger.error("result #{rc} from '#{string}'.")
            rc

          {rc, :info} ->
            Logger.info("result #{rc} from '#{string}'.")
            rc
        end

      errors ->
        Logger.error("Got errors #{inspect(errors)} from #{inspect(args)}")
    end
  end

  defp run_commands(_state, [], _values, _on_nonzero) do
    0
  end

  defp run(state, cmd, values, on_nonzero \\ :error) do
    values = for {key, val} <- values, into: %{}, do: {Atom.to_string(key), val}

    cmds = Map.fetch!(state.commands, cmd)
    run_commands(state, cmds, values, on_nonzero)
  end

  defp play_sound(state, sound) do
    case Map.get(state.sounds, sound) do
      nil -> nil
      sound_file -> run(state, :play, file: sound_file)
    end
  end

  defp say(state, text, volume) do
    say_volume =
      case volume do
        nil -> state.volumes.say
        volume -> volume
      end

    set_volume(state, say_volume)

    play_sound(state, "prefix")
    run(state, :say, text: text)
    play_sound(state, "repeat")
    run(state, :say, text: text)
    play_sound(state, "postfix")
    nil
  end

  defp music_paused?(state) do
    case run(state, :music_pause, [], :info) do
      0 -> true
      _ -> false
    end
  end

  defp set_volume(state, volume) do
    run(state, :volume, volume: volume)
  end

  defp music_resume(state) do
    set_volume(state, state.volumes.music)
    run(state, :music_resume, [])
    nil
  end

  defp music_play(state, play_list) do
    set_volume(state, state.volumes.music)
    run(state, :music_play, play_list: play_list)
    nil
  end

  defp music_stop(state) do
    run(state, :music_stop, [])
  end

  defp prepend_sound(sound_list, %{sound: nil}) do
    sound_list
  end

  defp prepend_sound(sound_list, %{sound: sound}) do
    [{:sound, sound} | sound_list]
  end

  defp prepend_sound(sound_list, _) do
    sound_list
  end

  defp prepend_message(sound_list, %{message: %{text: text, volume: volume}}) do
    [{:say, text, volume} | sound_list]
  end

  defp prepend_message(sound_list, %{message: %{text: text}}) do
    [{:say, text, nil} | sound_list]
  end

  defp prepend_message(sound_list, _), do: sound_list

  defp prepend_music(sound_list, %{music: %{stop: true}}) do
    [{:music, nil} | sound_list]
  end

  defp prepend_music(sound_list, %{music: %{play_list: nil}}), do: sound_list

  defp prepend_music(sound_list, %{music: %{play_list: play_list}}) do
    [{:music, play_list} | sound_list]
  end

  defp prepend_music(sound_list, _), do: sound_list

  defp get_sound_list(action) do
    []
    |> prepend_sound(action)
    |> prepend_message(action)
    |> prepend_music(action)
    |> Enum.reverse()
  end

  defp process_sound_list(_state, []), do: nil

  defp process_sound_list(state, [head | tail]) do
    case head do
      {:sound, sound} ->
        play_sound(state, sound)

      {:say, text, volume} ->
        say(state, text, volume)

      {:music, nil} ->
        music_stop(state)

      {:music, play_list} ->
        music_play(state, play_list)
    end

    process_sound_list(state, tail)

    nil
  end

  defp sound_list_has_music([]), do: false
  defp sound_list_has_music([{:music, _} | _]), do: true
  defp sound_list_has_music([_ | tail]), do: sound_list_has_music(tail)

  @spec handle_execute(state :: Config.t(), action :: RoboticaPlugins.Action.t()) :: nil
  defp handle_execute(state, action) do
    sound_list = get_sound_list(action)

    if length(sound_list) > 0 do
      paused = music_paused?(state)

      process_sound_list(state, sound_list)

      if not sound_list_has_music(sound_list) do
        if paused do
          music_resume(state)
        else
          set_volume(state, state.volumes.music)
        end
      end
    else
      set_volume(state, state.volumes.music)
    end

    nil
  end

  def handle_command(state, command) do
    state =
      case get_in(command.music, [:volume]) do
        nil ->
          state

        volume ->
          volumes = %{state.volumes | music: volume}
          %Config{state | volumes: volumes}
      end

    handle_execute(state, command)

    state
  end

  def handle_cast({:mqtt, _, :command, command}, state) do
    state =
      case Robotica.Config.validate_audio_command(command) do
        {:ok, command} ->
          handle_command(state, command)

        {:error, error} ->
          Logger.error("Invalid audio command received: #{inspect(error)}.")
          state
      end

    {:noreply, state}
  end

  def handle_cast({:execute, action}, state) do
    state = handle_command(state, action)
    {:noreply, state}
  end
end
