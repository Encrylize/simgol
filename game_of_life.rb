require "curses"


module CellState
  DEAD = 0
  ALIVE = 1
end


class GameOfLife
  attr_reader :grid, :grid_dimensions

  def initialize(start_grid)
    @grid = start_grid
    @grid_dimensions = {:height => @grid.size(), :width => @grid[0].size()}
  end

  def advance
    new_grid = Array.new(grid_dimensions[:height]) do
      Array.new(grid_dimensions[:width])
    end

    new_grid.each_with_index do |line, y|
      line.each_with_index do |cell, x|
        neighborhood = get_neighborhood(x, y)
        sum = neighborhood.inject(:+)
        case sum
        when 3
          new_grid[y][x] = CellState::ALIVE
        when 4
          new_grid[y][x] = @grid[y][x]
        else
          new_grid[y][x] = CellState::DEAD
        end
      end
    end

    @grid = new_grid
  end

  def get_neighborhood(x, y)
    neighborhood = []

    (-1..1).each do |y_i|
      (-1..1).each do |x_i|
        neighborhood << @grid.fetch(y + y_i, []).fetch(x + x_i, CellState::DEAD)
      end
    end

    return neighborhood
  end

  def draw
    Curses.clear
    @grid.each do |line|
      line.each {|cell| Curses.addch(cell == CellState::ALIVE ? 'O' : 'X')}
      Curses.addch("\n")
    end
    Curses.refresh
  end
end


gol = GameOfLife.new([[0, 0, 0, 0, 0],
                      [0, 0, 1, 0, 0],
                      [0, 0, 1, 0, 0],
                      [0, 0, 1, 0, 0],
                      [0, 0, 0, 0, 0]])

Curses.init_screen
begin
  gol.draw
  while Curses.getch
    gol.advance
    gol.draw
  end
ensure
  Curses.close_screen
end
