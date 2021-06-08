defmodule RoboticaPlugins.EventBus do
  @moduledoc """
  Defines helper functions from EventBus
  """

  alias EventBus.Model.Event
  alias EventBus.Util.Base62
  alias EventBus.Util.MonotonicTime

  defmacro __using__(_) do
    quote do
      require RoboticaPlugins.EventBus
      @eb_source String.replace("#{__MODULE__}", "Elixir.", "")
    end
  end

  @spec notify_with_source(String.t(), atom(), any()) :: :ok
  def notify_with_source(source, topic, data) do
    id = Base62.unique_id()
    initialized_at = MonotonicTime.now()

    %Event{
      id: id,
      topic: topic,
      transaction_id: id,
      data: data,
      initialized_at: initialized_at,
      occurred_at: MonotonicTime.now(),
      source: source
    }
    |> EventBus.notify()
  end

  defmacro notify(topic, data) do
    quote do
      RoboticaPlugins.EventBus.notify_with_source(@eb_source, unquote(topic), unquote(data))
    end
  end
end
