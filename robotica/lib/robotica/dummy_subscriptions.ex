defmodule Robotica.DummySubscriptions do
  use GenServer
  require Logger

  ## Client API

  @spec start_link(opts :: list) :: {:ok, pid} | {:error, String.t()}
  def start_link(opts) do
    GenServer.start_link(__MODULE__, :ok, opts)
  end

  ## Server Callbacks

  def init(:ok) do
    {:ok, %{}}
  end

  def handle_call(_, _from, state) do
    {:reply, nil, state}
  end
end
