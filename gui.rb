#!/usr/bin/ruby

BOARD_WIDTH = 8
BOARD_HEIGHT = 8
DEBUG = true

require 'Qt4'
require 'state.rb'
require 'chess.rb'
BLACK = "black"
WHITE = "white"
class ChessBoard < Qt::Widget
	slots 'piecePressed()'
	attr :pressedRow, true
	attr :pressedCol, true

	def initialize(parent = nil)
		super(parent)
		resize(400, 400)
		@clickedPiece = nil
		@pressedRow = 0
		@pressedCol = 0
		@chessLayout = Qt::GridLayout.new(self)
		@chessLayout.setSpacing(0)
		@chessLayout.setContentsMargins(0, 0, 0, 0)
		setLayout(@chessLayout)

		@buttonArray = Array.new
		for row in 0.upto(BOARD_HEIGHT-1)
			@buttonArray[row] = Array.new
			for col in 0.upto(BOARD_WIDTH-1)
				if (row + col) % 2 == 0
					color = WHITE
				else
					color = BLACK
				end
				@buttonArray[row][col] = Square.new(color, row, col, self)
				@chessLayout.addWidget(@buttonArray[row][col], row, col)
				connect(@buttonArray[row][col], SIGNAL('selected()'), self, SLOT('piecePressed()'))
			end
		end


		setBoard()

		c = Chess.new
		p c.enumerate_all_moves(@buttonArray)
		p @buttonArray

	end

	def setBoard()
		for i in 0.upto(BOARD_HEIGHT-1)
			@buttonArray[1][i].state = PawnState.new(1, i, WHITE)
			@buttonArray[6][i].state = PawnState.new(6, i, BLACK)
		end

		#place rooks
		@buttonArray[0][0].state = RookState.new(0, 0, WHITE)
		@buttonArray[0][7].state = RookState.new(0, 7, WHITE)
		@buttonArray[7][0].state = RookState.new(7, 0, BLACK)
		@buttonArray[7][7].state = RookState.new(7, 7, BLACK)

		#place knights
		@buttonArray[0][1].state = KnightState.new(0, 1, WHITE)
		@buttonArray[0][6].state = KnightState.new(0, 6, WHITE)
		@buttonArray[7][1].state = KnightState.new(7, 1, BLACK)
		@buttonArray[7][6].state = KnightState.new(7, 6, BLACK)

		#place bishops
		@buttonArray[0][2].state = BishopState.new(0, 2, WHITE)
		@buttonArray[0][5].state = BishopState.new(0, 5, WHITE)
		@buttonArray[7][2].state = BishopState.new(7, 2, BLACK)
		@buttonArray[7][5].state = BishopState.new(7, 5, BLACK)

		#place Kings
		@buttonArray[0][3].state = KingState.new(0, 3, WHITE)
		@buttonArray[7][3].state = KingState.new(7, 3, BLACK)

		#place Queens
		@buttonArray[0][4].state = QueenState.new(0, 4, WHITE)
		@buttonArray[7][4].state = QueenState.new(7, 4, BLACK)
	end

	def piecePressed
		if (@clickedPiece == nil) then
			c = Chess.new
			@array_moves = c.enumerate_move_destinations(@buttonArray, @pressedRow, @pressedCol)
			return if @array_moves.nil?

			for moves in @array_moves
				tmp = @buttonArray[moves[0]][moves[1]]
				tmp.setStyleSheet("QPushButton { background-color: #{tmp.color}; border: 5px solid green; padding:none;}")
			end

			@clickedPiece = @buttonArray[@pressedRow][@pressedCol]
		else
			return unless @array_moves.include?([@pressedRow, @pressedCol])
			tmp = @buttonArray[@pressedRow][@pressedCol]
			tmp.swap_state(@clickedPiece)

			for moves in @array_moves
				tmp = @buttonArray[moves[0]][moves[1]]
				tmp.setStyleSheet("QPushButton { background-color: #{tmp.color}; padding:none; border:none;}")
			end

			@clickedPiece =  nil
		end
	end
end

class Square < Qt::PushButton
	attr_accessor :color, :state

	slots 'pressed()'
	signals 'selected()'

	def initialize(color, row, col, parent = nil)
		super(parent)
		@row = row
		@col = col
		@color = color
		@state= BaseState.new(row, col, WHITE)
		setUpSizePolicy
		setStyleSheet("QPushButton { background-color: #{color}; padding:none; border:none;}");
		setMinimumSize(Qt::Size.new(60, 60))
		setMaximumHeight(16777215)
		connect(self, SIGNAL('clicked()'), self, SLOT('pressed()'))
	end

	def setUpSizePolicy
		policy = sizePolicy
		policy.setControlType(0x4000)
		policy.setHorizontalStretch(0)
		policy.setVerticalStretch(0)
		setSizePolicy(sizePolicy)
	end

	def resizeEvent(event)
		setIconSize(size())
	end

	def sizeHint
		height = parent.size().height() / 8
		size = Qt::Size.new(height, height)
		return size
	end

	def pressed()
		parent.pressedRow = @row
		parent.pressedCol = @col
		emit selected()
	end

	def state=(val)
		@state = val
		setIcon(@state.icon)
	end

	def swap_state(bttn2)
		state.move_to(bttn2.state)

		tmp = @state
		@state = bttn2.state
		bttn2.state = tmp
	end

	def inspect
		"<Square [#{@row}, #{@col}]: (#{@color}) #{@state.class}: #{@state.inspect}>"
	end
end

app = Qt::Application.new(ARGV)
chess = ChessBoard.new
chess.show
app.exec
