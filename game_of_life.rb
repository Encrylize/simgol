require 'curses'
require 'forwardable'


module CellState
  DEAD = 0
  ALIVE = 1
end


class GameOfLifeGrid
  include Enumerable
  extend Forwardable

  attr_reader :grid, :dimensions
  def_delegators :@grid, :each, :[]

  def initialize(start_grid)
    @grid = start_grid
    @dimensions = {:height => @grid.size(), :width => @grid[0].size()}
  end

  def advance
    new_grid = Array.new(dimensions[:height]) do
      Array.new(dimensions[:width])
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
end


class GridWindow < Curses::Window
  attr_reader :grid, :grid_x, :grid_y
  BOX_VERT_CHAR = '|'
  BOX_HORIZ_CHAR = '-'
  BOX_CORNER_CHAR = '*'

  def initialize(height, width, top, left, grid)
    super(height, width, top, left)
    @grid = grid
    @grid_x = 0
    @grid_y = 0
  end

  def grid_x=(x)
    @grid_x = x unless x < 0 or x > @grid.dimensions[:width] - maxx + 2
  end

  def grid_y=(y)
    @grid_y = y unless y < 0 or y > @grid.dimensions[:height] - maxy + 2
  end

  def draw_horiz_frame
    addch(BOX_CORNER_CHAR)
    (maxx - 2).times { addch(BOX_HORIZ_CHAR) }
    addch(BOX_CORNER_CHAR)
  end

  def draw
    clear
    draw_horiz_frame

    grid[@grid_y..@grid_y + maxy - 3].each do |line|
      addch(BOX_VERT_CHAR)
      line[@grid_x..@grid_x + maxx - 3].each do |cell|
        addch(cell == CellState::ALIVE ? 'O' : 'X')
      end
      addch(BOX_VERT_CHAR)
    end

    draw_horiz_frame
    refresh
  end
end


grid = GameOfLifeGrid.new([[0, 0, 0, 0, 0],
                           [0, 0, 1, 0, 0],
                           [0, 0, 1, 0, 0],
                           [0, 0, 1, 0, 0],
                           [0, 0, 0, 0, 0]])

Curses.init_screen
begin
  win = GridWindow.new(5, 5, 0, 0, grid)
  win.draw
  while ch = win.getch
    case ch
    when 'w'
      win.grid_y -= 1
    when 's'
      win.grid_y += 1
    when 'a'
      win.grid_x -= 1
    when 'd'
      win.grid_x += 1
    when 'u'
      grid.advance
    end
    win.draw
  end
ensure
  Curses.close_screen
end
