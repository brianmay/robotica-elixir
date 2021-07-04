defmodule Robotica.Plugins.Audio do
  @moduledoc """
  Audio plugin
  """

  use GenServer
  use Robotica.Plugin
  use RoboticaCommon.EventBus
  require Logger

  import Robotica.Types
  alias RoboticaCommon.Strings

  defmodule Commands do
    @moduledoc false
    @type t :: %__MODULE__{
            init: list(String.t()),
            volume: list(String.t()),
            play: list(String.t()),
            say: list(String.t()),
            music_play: list(String.t()),
            music_stop: list(String.t()),
            music_pause: list(String.t()),
            music_resume: list(String.t())
          }
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
    @moduledoc false
    @type t :: %__MODULE__{
            commands: Commands.t(),
            sounds: %{required(String.t()) => String.t()},
            volumes: %{required(atom()) => integer}
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

  defmodule State do
    @moduledoc false
    @type t :: %__MODULE__{
            location: String.t(),
            device: String.t(),
            config: Config.t(),
            volumes: %{required(atom()) => integer}
          }
    @enforce_keys [:location, :device, :config, :volumes]
    defstruct [:location, :device, :config, :volumes]
  end

  ## Server Callbacks

  @spec init(Robotica.Plugin.t()) :: {:ok, State.t()}
  def init(plugin) do
    state = %State{
      location: plugin.location,
      device: plugin.device,
      config: plugin.config,
      volumes: plugin.config.volumes
    }

    run(state, :init, [])
    music_stop(state)
    publish_volume(state, "music", state.volumes.music)
    publish_volume(state, "message", state.volumes.message)
    set_volume(state, state.volumes.music)

    {:ok, state}
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
      message: {:integer, true},
      music: {:integer, true}
    }
  end

  def config_schema do
    %{
      struct_type: Config,
      commands: {commands(), true},
      sounds: {sounds(), true},
      volumes: {volumes(), true}
    }
  end

  @spec publish_raw(State.t(), String.t(), String.t()) :: :ok
  defp publish_raw(%State{} = state, topic, value) do
    case RoboticaCommon.Mqtt.publish_state_raw(state.location, state.device, value, topic: topic) do
      :ok ->
        :ok

      {:error, msg} ->
        Logger.error("Audio #{state.location}/#{state.device}: publish_raw() got #{msg}")
    end

    :ok
  end

  @spec publish_play_list(State.t(), String.t() | nil) :: :ok
  defp publish_play_list(%State{} = state, play_list) do
    play_list = if play_list == nil, do: "STOP", else: play_list
    publish_raw(state, "play_list", play_list)
  end

  @spec publish_volume(State.t(), String.t(), integer) :: :ok
  defp publish_volume(%State{} = state, volume, value) do
    publish_raw(state, "volume/#{volume}", Integer.to_string(value))
  end

  @spec publish_error(State.t()) :: :ok
  defp publish_error(%State{} = state) do
    publish_play_list(state, "ERROR")
  end

  @spec run_commands(State.t(), list(String.t()), map(), :error | :info) ::
          :ok | {:error, String.t()} | {:rc, pos_integer}
  defp run_commands(%State{} = state, [cmd | tail], values, on_nonzero) do
    [cmd | args] = cmd
    args = Enum.map(args, &Strings.solve_string_combined(&1, values))

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

        try do
          {_output, rc} = System.cmd(cmd, args)

          case {rc, on_nonzero} do
            {0, _} ->
              Logger.info("result 0 from '#{string}'.")
              run_commands(state, tail, values, on_nonzero)

            {rc, :error} ->
              Logger.error("result #{rc} from '#{string}'.")
              {:error, "result #{rc} from '#{string}'"}

            {rc, :info} ->
              Logger.info("result #{rc} from '#{string}'.")
              {:rc, rc}
          end
        rescue
          error -> {:error, "Got error #{inspect(error.original)}"}
        end

      errors ->
        {:error, "Got errors #{inspect(errors)} from #{inspect(args)}"}
    end
  end

  defp run_commands(%State{}, [], _values, _on_nonzero) do
    :ok
  end

  @spec run(State.t(), atom(), keyword(), :error | :info) ::
          :ok | {:error, String.t()} | {:rc, pos_integer}
  defp run(%State{} = state, cmd, values, on_nonzero \\ :error) do
    values = for {key, val} <- values, into: %{}, do: {Atom.to_string(key), val}

    cmds = Map.fetch!(state.config.commands, cmd)
    run_commands(state, cmds, values, on_nonzero)
  end

  @spec do_play_sound(State.t(), String.t()) :: :ok
  defp do_play_sound(%State{} = state, sound) do
    case Map.get(state.config.sounds, sound) do
      nil -> nil
      sound_file -> run(state, :play, file: sound_file)
    end

    :ok
  end

  @spec play_sound(State.t(), String.t()) :: :ok
  defp play_sound(%State{} = state, sound) do
    set_volume(state, state.volumes.message)
    do_play_sound(state, sound)
    set_volume(state, state.volumes.music)
    :ok
  end

  @spec say(State.t(), String.t()) :: :ok
  defp say(%State{} = state, text) do
    set_volume(state, state.volumes.message)

    do_play_sound(state, "prefix")
    run(state, :say, text: text)
    do_play_sound(state, "repeat")
    run(state, :say, text: text)
    do_play_sound(state, "postfix")

    set_volume(state, state.volumes.music)
    :ok
  end

  @spec music_paused?(State.t()) :: boolean
  defp music_paused?(%State{} = state) do
    case run(state, :music_pause, [], :info) do
      :ok -> true
      _ -> false
    end
  end

  @spec set_volume(State.t(), integer) :: :ok
  defp set_volume(%State{} = state, volume) do
    run(state, :volume, volume: volume)
    :ok
  end

  @spec music_resume(State.t()) :: :ok
  defp music_resume(%State{} = state) do
    set_volume(state, state.volumes.music)
    run(state, :music_resume, [])
    :ok
  end

  @spec music_play(State.t(), String.t()) :: :ok
  defp music_play(%State{} = state, play_list) do
    set_volume(state, state.volumes.music)

    case run(state, :music_play, play_list: play_list) do
      :ok -> publish_play_list(state, play_list)
      _ -> publish_error(state)
    end

    :ok
  end

  @spec music_stop(State.t()) :: :ok
  defp music_stop(%State{} = state) do
    case run(state, :music_stop, []) do
      :ok -> publish_play_list(state, nil)
      _ -> publish_error(state)
    end

    :ok
  end

  @spec prepend_sound(list(tuple), map()) :: list(tuple)
  defp prepend_sound(sound_list, %{sound: nil}) do
    sound_list
  end

  defp prepend_sound(sound_list, %{sound: sound}) do
    [{:sound, sound} | sound_list]
  end

  defp prepend_sound(sound_list, _) do
    sound_list
  end

  defp prepend_message(sound_list, %{message: %{text: text}}) do
    [{:say, text} | sound_list]
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

  @spec get_sound_list(map()) :: list(tuple)
  defp get_sound_list(action) do
    []
    |> prepend_sound(action)
    |> prepend_message(action)
    |> prepend_music(action)
    |> Enum.reverse()
  end

  @spec process_sound_list(State.t(), list(tuple)) :: :ok
  defp process_sound_list(%State{}, []), do: :ok

  defp process_sound_list(%State{} = state, [head | tail]) do
    case head do
      {:sound, sound} ->
        play_sound(state, sound)

      {:say, text} ->
        say(state, text)

      {:music, nil} ->
        music_stop(state)

      {:music, play_list} ->
        music_play(state, play_list)
    end

    process_sound_list(state, tail)
  end

  @spec sound_list_has_music(list(tuple)) :: boolean
  defp sound_list_has_music([]), do: false
  defp sound_list_has_music([{:music, _} | _]), do: true
  defp sound_list_has_music([_ | tail]), do: sound_list_has_music(tail)

  @spec handle_execute(state :: State.t(), action :: map()) :: nil
  defp handle_execute(%State{} = state, action) do
    publish(state.location, state.device, action)

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

  @spec handle_command(Robotica.Plugins.Audio.State.t(), map()) ::
          Robotica.Plugins.Audio.State.t()
  def handle_command(%State{} = state, command) do
    state =
      case command.volume do
        nil ->
          state

        volume ->
          music_volume =
            case volume.music do
              nil -> state.volumes.music
              value -> value
            end

          msg_volume =
            case volume.message do
              nil -> state.volumes.message
              value -> value
            end

          publish_volume(state, "music", music_volume)
          publish_volume(state, "message", msg_volume)

          volume = %{state.volumes | music: music_volume, message: msg_volume}
          %State{state | volumes: volume}
      end

    handle_execute(state, command)

    state
  end

  def handle_cast({:mqtt, _, :command, command}, state) do
    state =
      case Robotica.Config.validate_audio_command(command) do
        {:ok, command} ->
          if command.type == "audio" or command.type == nil do
            handle_command(state, command)
          else
            Logger.info("Wrong type #{command.type}, expected audio")
            state
          end

        {:error, error} ->
          Logger.error("Invalid audio command received: #{inspect(error)}.")
          state
      end

    {:noreply, state}
  end
end
