defmodule ElixirMmoWeb.JoinGameLive do
  use ElixirMmoWeb, :live_view

  @impl true
  def mount(_params, _session, socket) do
    {:ok, socket}
  end

  @impl true
  def handle_event("join_game", %{"hero_name" => ""} = _params, socket) do
    {:noreply, put_flash(socket, :error, "Please choose a name")}
  end

  @impl true
  def handle_event("join_game", %{"hero_name" => hero_name} = _params, socket) do
    {:noreply, redirect(socket, to: "/game?name=#{hero_name}")}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <h1 class="text-center text-4xl">Join Game</h1>

    <.form for={%{}} phx-submit="join_game">
      <.label for="hero_name">Hero name</.label>
      <.input type="text" name="hero_name" value={get_random_hero_name()} />
      <button class="m-2 float-right py-4 px-8 text-white bg-blue-400 rounded-md border">Join</button>
    </.form>
    """
  end

  defp get_random_hero_name do
    Path.join(:code.priv_dir(:elixir_mmo), "static/random_hero_names.txt")
    |> File.read!()
    |> String.split()
    |> Enum.random()
  end
end
