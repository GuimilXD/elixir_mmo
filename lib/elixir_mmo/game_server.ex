defmodule ElixirMmo.GameServer do
  alias ElixirMmo.Hero
  use DynamicSupervisor

  @name __MODULE__

  def start_link(init_arg) do
    DynamicSupervisor.start_link(@name, init_arg, name: @name)
  end

  @impl true
  def init(_init_arg) do
    DynamicSupervisor.init(strategy: :one_for_one)
  end

  def add_hero(name) do
    child_spec = %{
      id: Hero,
      start: {Hero, :start_link, [name]},
      restart: :transient
    }

    case DynamicSupervisor.start_child(@name, child_spec) do
      {:ok, pid}  ->
        Phoenix.PubSub.broadcast!(ElixirMmo.PubSub, "hero:updates", Hero.get_state_by_pid(pid))
      _ -> :ok
    end

  end

  def remove_hero(name) do
    case Hero.get_pid_by_name(name) do
      pid when is_pid(pid) ->
        hero = Hero.get_state_by_pid(pid)

        # broadcast a empty hero struct to remove it from the list
        # the benefits of implementing proper deletion (handling more events, etc...) is probably not worth the extra complexity
        # TODO: test if proper deletion is needed
        Phoenix.PubSub.broadcast!(ElixirMmo.PubSub, "hero:updates", %Hero{name: hero.name})

        DynamicSupervisor.terminate_child(@name, pid)
      nil ->
        :ok
    end
  end

  def get_hero_by_name(name) do
    Hero.get_state(name)
  end

  def list_heroes() do
    DynamicSupervisor.which_children(@name)
    |> Enum.map(fn hero ->
        {_, pid, :worker, _} = hero

        Hero.get_state_by_pid(pid)
    end)
  end
end
