# TODO: This is a hard-coded version of the mapgrid module.
# However, it was written in a way that makes it easy to change the internal implementation without changing the public API
defmodule ElixirMmo.MapGrid do
  @columns 10
  @rows 10

  @walls MapSet.new([{5, 0}, {5, 1}, {5, 2}, {5, 3}, {5, 4}])

  def get_random_position do
    pos = get_random_position_internal()

    # using recursion to avoid generating positions inside walls
    if is_wall?(pos) do
      get_random_position()
    else
      pos
    end
  end

  defp get_random_position_internal do
    # :rand.uniform/1 returns an int ranging from 1 to N inclusive.
    # We want a number from 0 to N-1, as arrays use 0-based indexing
    {:rand.uniform(@rows) - 1, :rand.uniform(@columns - 1)}
  end

  def is_wall?(position) do
    MapSet.member?(@walls, position)
  end

  def is_point_inside?({x, y}) do
    (x >= 0 and x < @rows) and (y >= 0 and y < @columns)
  end

  def get_columns, do: @columns
  def get_rows, do: @rows
end
