defmodule ElixirMmo.Hero do
  alias Phoenix.PubSub
  alias ElixirMmo.MapGrid
  alias ElixirMmo.Hero

  defstruct [:name, :position, :is_alive]

  @name __MODULE__
  # 5 seconds
  @respawn_delay 5000

  # Server-side code

  use GenServer

  def start_link(name) do
    new_hero = %Hero{name: name, position: MapGrid.get_random_position(), is_alive: true}

    GenServer.start_link(@name, new_hero, name: via_tuple(name))
  end

  @impl true
  def init(player) do
    {:ok, player}
  end

  @impl true
  def handle_call(:get_state, _from, state) do
    {:reply, state, state}
  end

  @impl true
  def handle_cast({:move, delta}, state) do
    new_hero = move_internal(state, delta)

    PubSub.broadcast!(ElixirMmo.PubSub, "hero:updates", new_hero)

    {:noreply, new_hero}
  end

  @impl true
  def handle_cast(:kill, state) do
    new_hero = %Hero{state | is_alive: false}

    PubSub.broadcast!(ElixirMmo.PubSub, "hero:updates", new_hero)

    Process.send_after(self(), :respawn, @respawn_delay)

    {:noreply, new_hero}
  end

  @impl true
  def handle_info(:respawn, %{name: name}) do
    new_hero = %Hero{name: name, position: MapGrid.get_random_position(), is_alive: true}

    PubSub.broadcast!(ElixirMmo.PubSub, "hero:updates", new_hero)

    {:noreply, new_hero}
  end

  defp via_tuple(name) do
    {:via, Registry, {ElixirMmo.HeroRegistry, name}}
  end

  defp move_internal(%Hero{} = hero, {dx, dy}) do
    {x, y} = hero.position

    new_pos = {x + dx, y + dy}

    if not MapGrid.is_wall?(new_pos) and MapGrid.is_point_inside?(new_pos) and hero.is_alive do
      %Hero{hero | position: new_pos}
    else
      hero
    end
  end

  # Public API
  def move(name, direction) do
    cast_by_name(name, {:move, direction})
  end

  def move_up(name) do
    move(name, {0, -1})
  end

  def move_down(name) do
    move(name, {0, 1})
  end

  def move_left(name) do
    move(name, {-1, 0})
  end

  def move_right(name) do
    move(name, {1, 0})
  end

  def kill(name) do
    cast_by_name(name, :kill)
  end

  def get_state(name) do
    call_by_name(name, :get_state)
  end

  def get_state_by_pid(pid) do
    GenServer.call(pid, :get_state)
  end

  def get_pid_by_name(name) do
    via_tuple(name) |> GenServer.whereis()
  end

  defp cast_by_name(name, command) do
    case get_pid_by_name(name) do
      pid when is_pid(pid) ->
        GenServer.cast(pid, command)

      nil ->
        {:error, "hero not found"}
    end
  end

  defp call_by_name(name, command) do
    case get_pid_by_name(name) do
      pid when is_pid(pid) ->
        GenServer.call(pid, command)

      nil ->
        {:error, "hero not found"}
    end
  end
end