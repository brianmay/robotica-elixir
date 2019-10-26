defmodule Robotica.Tesla do
  use EventBus.EventSource

  def publish_state(state) do
    EventSource.notify %{topic: :tesla} do
      state
    end
  end
end
