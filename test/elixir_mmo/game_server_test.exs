defmodule GameServerTest do
  use ExUnit.Case, async: true

  alias ElixirMmo.GameServer

  setup do
    # GameServer is not started automatically in tests, please see application.ex for more information.
    # This is done to ensure isolation between test cases
    {:ok, _} = GameServer.start_link(%{})

    :ok
  end

  describe "add_hero/1" do
    test "spawns a new hero genserver with a given name" do
      assert :ok = GameServer.add_hero("hercules")
      assert :ok = GameServer.add_hero("achilles")

      assert %{workers: 2} = DynamicSupervisor.count_children(GameServer)
      assert length(DynamicSupervisor.which_children(GameServer)) == 2
    end
  end

  describe "list_heroes/0" do
    test "returns a list of all heroes added" do
      heroes_names = ["perseus", "cadmus"]

      add_heroes(heroes_names)

      heroes = GameServer.list_heroes()

      assert length(heroes) == 2
      assert Enum.all?(heroes, &(&1.name in heroes_names))
    end
  end

  describe "remove_hero/1" do
    test "removes a the hero from the list but other ones remaing" do
      heroes_names = ["hercules", "achilles"]

      add_heroes(heroes_names)

      GameServer.remove_hero("hercules")

      heroes = GameServer.list_heroes()

      assert length(heroes) == 1
      assert not Enum.any?(heroes, &(&1.name == "hercules"))
    end
  end

  defp add_heroes(heroes) do
    Enum.each(heroes, &GameServer.add_hero/1)
  end
end
