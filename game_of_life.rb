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

  def initialize(height, width)
    @dimensions = {:height => height, :width => width}
    @grid = Array.new(dimensions[:height]) do
      Array.new(dimensions[:width], CellState::DEAD)
    end
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
  attr_reader :grid, :grid_anchor_x, :grid_anchor_y
  attr_accessor :cur_x, :cur_y
  BOX_VERT_CHAR = '|'
  BOX_HORIZ_CHAR = '-'
  BOX_CORNER_CHAR = '*'
  DEAD_CELL_CHAR = '.'
  ALIVE_CELL_CHAR = '#'

  def initialize(height, width, top, left, grid)
    super(height, width, top, left)
    self.keypad = true
    @grid = grid
    @grid_anchor_x = 0
    @grid_anchor_y = 0
    @cur_x = grid_width / 2
    @cur_y = grid_height / 2
  end

  def grid_anchor_x=(x)
    @grid_anchor_x = x unless x < 0 or x > @grid.dimensions[:width] - maxx + 2
  end

  def grid_anchor_y=(y)
    @grid_anchor_y = y unless y < 0 or y > @grid.dimensions[:height] - maxy + 2
  end

  def cur_x=(x)
    if x < 0 or x > grid_width
      self.grid_anchor_x -= @cur_x - x
    else
      @cur_x = x
    end
  end

  def cur_y=(y)
    if y < 0 or y > grid_width
      self.grid_anchor_y -= @cur_y - y
    else
      @cur_y = y
    end
  end

  def grid_width
    maxx - 3
  end

  def grid_height
    maxy - 3
  end

  def draw_horiz_frame
    addch(BOX_CORNER_CHAR)
    (maxx - 2).times { addch(BOX_HORIZ_CHAR) }
    addch(BOX_CORNER_CHAR)
  end

  def toggle_cell
    x = @grid_anchor_x + @cur_x
    y = @grid_anchor_y + @cur_y
    @grid[y][x] = @grid[y][x] == CellState::ALIVE ? CellState::DEAD : CellState::ALIVE
  end

  def draw
    clear
    draw_horiz_frame

    @grid[@grid_anchor_y..@grid_anchor_y + grid_height].each do |line|
      addch(BOX_VERT_CHAR)
      line[@grid_anchor_x..@grid_anchor_x + grid_width].each do |cell|
        addch(cell == CellState::ALIVE ? ALIVE_CELL_CHAR : DEAD_CELL_CHAR)
      end
      addch(BOX_VERT_CHAR)
    end

    draw_horiz_frame
    setpos(cur_y + 1, cur_x + 1)
    refresh
  end

  def loop
    draw
    while ch = getch
      case ch
      when 'w'
        self.grid_anchor_y -= 1
      when 's'
        self.grid_anchor_y += 1
      when 'a'
        self.grid_anchor_x -= 1
      when 'd'
        self.grid_anchor_x += 1
      when Curses::Key::UP
        self.cur_y -= 1
      when Curses::Key::DOWN
        self.cur_y += 1
      when Curses::Key::LEFT
        self.cur_x -= 1
      when Curses::Key::RIGHT
        self.cur_x += 1
      when ' '
        toggle_cell
      when 'u'
        grid.advance
      end
      draw
    end
  end
end


grid = GameOfLifeGrid.new(300, 300)

Curses.init_screen
Curses.noecho
begin
  stdscr = Curses::stdscr
  win = GridWindow.new(stdscr.maxy / 2, stdscr.maxx / 2, 0, 0, grid)
  win.loop
ensure
  Curses.close_screen
end
