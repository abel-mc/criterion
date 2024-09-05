defmodule Criterion.Reporter.Store do
  use GenServer

  @impl true
  def init(_opts) do
    {:ok, []}
  end

  @impl true
  def handle_call(:get_steps, _, state) do
    {:reply, state, state}
  end

  @impl true
  def handle_cast({:add_step, {_feature, _scenario, _step, _status} = step}, state) do
    {:noreply, state ++ [step]}
  end

  def get_steps() do
    GenServer.call(__MODULE__, :get_steps)
  end

  def add_step(payload) do
    GenServer.cast(__MODULE__, {:add_step, payload})
  end

  def start do
    GenServer.start_link(__MODULE__, [], name: __MODULE__)
  end
end
