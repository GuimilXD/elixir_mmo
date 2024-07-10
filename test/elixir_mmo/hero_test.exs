defmodule HeroTest do
  alias ElixirMmo.Hero

  use ExUnit.Case, async: true

  @test_hero "test_hero"
  @hero_respawn_delay Application.compile_env!(:elixir_mmo, :hero_respawn_delay)

  setup do
    {:ok, pid} = Hero.start_link(@test_hero, {0, 0})

    %{hero_name: @test_hero, pid: pid}
  end

  describe "move_*/1" do
    # TODO: Write tests that verify wall collision and out of bounds movement
    test "should not move the hero if they are dead" do
      Hero.kill(@test_hero)

      assert %{is_alive: false, position: original_pos} = Hero.get_state(@test_hero)

      Hero.move_down(@test_hero)

      %{position: new_pos} = Hero.get_state(@test_hero)

      assert new_pos == original_pos

      Hero.move_up(@test_hero)

      %{position: new_pos} = Hero.get_state(@test_hero)

      assert new_pos == original_pos
    end
  end

  describe "kill/1" do
    test "sets is_alive to false and respawns hero after delay" do
      Hero.kill(@test_hero)

      assert %{is_alive: false} = Hero.get_state(@test_hero)

      Process.sleep(2 * @hero_respawn_delay)

      assert %{is_alive: true} = Hero.get_state(@test_hero)
    end
  end

  # TODO: write a test for perform_attack, currently it needs GameServer to be runnning so that it can fetch other heroes
end
