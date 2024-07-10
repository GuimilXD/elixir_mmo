defmodule ElixirMmoWeb.GameLive do
  alias ElixirMmo.Hero
  alias ElixirMmo.MapGrid
  alias ElixirMmo.GameServer
  use ElixirMmoWeb, :live_view

  @impl true
  def mount(params, _session, socket) do
    if connected?(socket), do: Phoenix.PubSub.subscribe(ElixirMmo.PubSub, "hero:updates")

    {:ok,
     socket
     |> assign_my_hero_name(params)
     |> assign_heroes()}
  end

  @impl true
  def handle_info({:removed_hero, name}, socket) do
    {:noreply, update(socket, :heroes, &Map.delete(&1, name))}
  end

  @impl true
  def handle_info(%Hero{} = updated_hero, socket) do
    {:noreply, update(socket, :heroes, &Map.put(&1, updated_hero.name, updated_hero))}
  end

  @impl true
  def handle_event(
        "keydown",
        %{"key" => " "},
        %{assigns: %{my_hero_name: my_hero_name}} = socket
      ) do
    Hero.perform_attack(my_hero_name)
    {:noreply, socket}
  end

  @impl true
  def handle_event("keydown", %{"key" => key}, %{assigns: %{my_hero_name: hero_name}} = socket) do
    mappings = %{
      "w" => &Hero.move_up/1,
      "a" => &Hero.move_left/1,
      "d" => &Hero.move_right/1,
      "s" => &Hero.move_down/1
    }

    if move_function = Map.get(mappings, key) do
      move_function.(hero_name)
    end

    {:noreply, socket}
  end

  # TODO: find a batter way of removing players from the list as their liveview connection terminates
  # terminate/2 is not guaranteed to run every time a liveview connection terminates
  @impl true
  def terminate(_reason, %{assigns: %{my_hero_name: name}} = _socket) do
    GameServer.remove_hero(name)
  end

  @impl true
  def render(assigns) do
    # TODO: use the values returned by MapGrid.get_rows/0 and MapGrid.get_columns/0
    ~H"""
    <div phx-window-keydown="keydown" class="m-auto w-max grid grid-cols-10 grid-rows-10">
      <%= for y <- 0..(MapGrid.get_columns() - 1) do %>
        <%= for x <- 0..(MapGrid.get_rows() - 1) do %>
          <div class={"#{get_color_for_tile(@my_hero_name, @heroes, {x, y})} border w-10 h-10 #{dim_saturation_if_dead(@heroes, {x, y})}"}>
          </div>
        <% end %>
      <% end %>
    </div>
    """
  end

  defp get_color_for_tile(my_hero_name, heroes, pos) do
    if MapGrid.is_wall?(pos) do
      "bg-black"
    else
      heroes_at_pos = get_heroes_at(heroes, pos)

      get_color_for_hero(heroes_at_pos, my_hero_name)
    end
  end

  defp get_color_for_hero([], _my_hero_name), do: "bg-transparent"

  defp get_color_for_hero(heroes_at_pos, my_hero_name) do
    if Enum.find(heroes_at_pos, fn hero -> hero.name == my_hero_name end) do
      "bg-blue-500"
    else
      "bg-red-600"
    end
  end

  defp get_heroes_at(heroes, target_pos) do
    heroes
    |> Enum.filter(fn {_name, hero} ->
      %{position: hero_position} = hero

      hero_position == target_pos
    end)
    |> Enum.map(fn {_name, hero} -> hero end)
  end

  defp dim_saturation_if_dead(heroes, pos) do
    hero = get_heroes_at(heroes, pos) |> List.first()

    case hero do
      %{is_alive: false} ->
        "saturate-50"

      _ ->
        ""
    end
  end

  defp assign_my_hero_name(socket, %{"name" => name} = _params) when name != "" do
    GameServer.add_hero(name)

    assign(socket, my_hero_name: name)
  end

  defp assign_my_hero_name(socket, _params), do: redirect(socket, to: "/")

  defp assign_heroes(socket) do
    # Converting the heroes list to a map so we don't have to interate through all heroes once only one hero is updated.
    assign(socket,
      heroes:
        GameServer.list_heroes()
        |> Enum.into(%{}, fn %Hero{name: name} = hero -> {name, hero} end)
    )
  end
end
