defmodule ElixirMmo.Hero do
  alias ElixirMmo.GameServer
  alias Phoenix.PubSub
  alias ElixirMmo.MapGrid
  alias ElixirMmo.Hero

  require Logger

  defstruct [:name, :position, :is_alive]

  @name __MODULE__
  @respawn_delay Application.compile_env!(:elixir_mmo, :hero_respawn_delay)

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

    Logger.debug("Hero moved, new state: #{inspect(new_hero)}")

    PubSub.broadcast!(ElixirMmo.PubSub, "hero:updates", new_hero)

    {:noreply, new_hero}
  end

  @impl true
  def handle_cast(:kill, %{is_alive: false} = state), do: {:noreply, state}

  @impl true
  def handle_cast(:kill, %{is_alive: true} = state) do
    new_hero = %Hero{state | is_alive: false}

    Logger.debug(
      "#{state.name} was killed, respawning in #{@respawn_delay} miliseconds. New state: #{inspect(new_hero)}"
    )

    PubSub.broadcast!(ElixirMmo.PubSub, "hero:updates", new_hero)

    Process.send_after(self(), :respawn, @respawn_delay)

    {:noreply, new_hero}
  end

  @impl true
  def handle_cast(:perform_attack, state) do
    heroes = GameServer.list_heroes()

    Logger.debug("#{state.name} performed an attack on #{inspect(state.position)}")

    {:noreply, perform_attack_internal(state, heroes)}
  end

  @impl true
  def handle_info(:respawn, %{name: name}) do
    new_hero = %Hero{name: name, position: MapGrid.get_random_position(), is_alive: true}

    Logger.debug("#{name} respawned. New state #{inspect(new_hero)}")
    PubSub.broadcast!(ElixirMmo.PubSub, "hero:updates", new_hero)

    {:noreply, new_hero}
  end

  defp via_tuple(name) do
    {:via, Registry, {ElixirMmo.HeroRegistry, name}}
  end

  defp adjacent_positions({x, y}) do
    for dx <- -1..1, dy <- -1..1 do
      {x + dx, y + dy}
    end
  end

  defp perform_attack_internal(state, []), do: state
  defp perform_attack_internal(%Hero{is_alive: false} = state, _heroes), do: state

  defp perform_attack_internal(%Hero{name: name, position: position} = state, heroes) do
    Enum.filter(heroes, fn %Hero{name: other_name, position: other_position} ->
      other_position in adjacent_positions(position) and name != other_name
    end)
    |> Enum.each(fn %{name: other_name} ->
      Hero.kill(other_name)

      Logger.debug("#{state.name}'s attack hit #{other_name}")
    end)

    state
  end

  defp move_internal(%{} = hero, {dx, dy}) do
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

  def perform_attack(name) do
    cast_by_name(name, :perform_attack)
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
