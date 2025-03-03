//
//  ContentView.swift
//  Reversi2
//
//  Created by Stephen Tim on 2025/2/8.
//
import SwiftUI

// 游戏逻辑模型
class ReversiGame: ObservableObject {
    @Published var board: [[Piece?]] = Array(repeating: Array(repeating: nil, count: 8), count: 8)
    @Published var currentPlayer: Piece = .black
    @Published var gameOver = false
    @Published var blackCount = 2
    @Published var whiteCount = 2
    
    enum Piece: String {
        case black = "●"
        case white = "○"
        
        var opposite: Piece {
            return self == .black ? .white : .black
        }
    }
    
    init() {
        // 初始布局
        board[3][3] = .white
        board[3][4] = .black
        board[4][3] = .black
        board[4][4] = .white
    }
    
    // 检查落子是否合法
    func isValidMove(row: Int, col: Int) -> Bool {
        guard board[row][col] == nil else { return false }
        
        for dx in -1...1 {
            for dy in -1...1 {
                if dx == 0 && dy == 0 { continue }
                if checkDirection(row: row, col: col, dx: dx, dy: dy) {
                    return true
                }
            }
        }
        return false
    }
    
    private func checkDirection(row: Int, col: Int, dx: Int, dy: Int) -> Bool {
        var x = row + dx
        var y = col + dy
        var foundOpposite = false
        
        while x >= 0 && x < 8 && y >= 0 && y < 8 {
            guard let piece = board[x][y] else { return false }
            if piece == currentPlayer {
                return foundOpposite
            } else {
                foundOpposite = true
            }
            x += dx
            y += dy
        }
        return false
    }
    
    // 放置棋子
    func placePiece(row: Int, col: Int) {
        guard isValidMove(row: row, col: col) else { return }
        
        var flipPieces: [(Int, Int)] = []
        
        for dx in -1...1 {
            for dy in -1...1 {
                if dx == 0 && dy == 0 { continue }
                let pieces = collectDirectionPieces(row: row, col: col, dx: dx, dy: dy)
                flipPieces.append(contentsOf: pieces)
            }
        }
        
        board[row][col] = currentPlayer
        flipPieces.forEach { board[$0][$1] = currentPlayer }
        
        updateCounts()
        checkGameOver()
        currentPlayer = currentPlayer.opposite
    }
    
    private func collectDirectionPieces(row: Int, col: Int, dx: Int, dy: Int) -> [(Int, Int)] {
        var x = row + dx
        var y = col + dy
        var pieces: [(Int, Int)] = []
        
        while x >= 0 && x < 8 && y >= 0 && y < 8 {
            guard let piece = board[x][y] else { return [] }
            if piece == currentPlayer {
                return pieces
            } else {
                pieces.append((x, y))
            }
            x += dx
            y += dy
        }
        return []
    }
    
    private func updateCounts() {
        var black = 0
        var white = 0
        for row in board {
            for piece in row {
                if piece == .black { black += 1 }
                if piece == .white { white += 1 }
            }
        }
        blackCount = black
        whiteCount = white
    }
    
    private func checkGameOver() {
        var hasValidMoves = false
        for i in 0..<8 {
            for j in 0..<8 {
                if isValidMove(row: i, col: j) {
                    hasValidMoves = true
                    break
                }
            }
        }
        if !hasValidMoves {
            gameOver = true
        }
    }
    
    func resetGame() {
        board = Array(repeating: Array(repeating: nil, count: 8), count: 8)
        currentPlayer = .black
        gameOver = false
        blackCount = 2
        whiteCount = 2
        // 重置初始布局
        board[3][3] = .white
        board[3][4] = .black
        board[4][3] = .black
        board[4][4] = .white
    }
}

// 游戏主视图
struct ReversiView: View {
    @StateObject private var game = ReversiGame()
    
    var body: some View {
        GeometryReader { geometry in
            let isPortrait = geometry.size.height > geometry.size.width
            VStack {
                ScoreView(game: game)
                
                BoardView(game: game)
                    .frame(width: min(geometry.size.width, geometry.size.height) * 0.9,
                           height: min(geometry.size.width, geometry.size.height) * 0.9)
                
                if isPortrait {
                    ControlView(game: game)
                        .padding()
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(Color.green.opacity(0.3))
            .overlay(
                Group {
                    if !isPortrait {
                        LandscapeControlView(game: game)
                    }
                }
            )
        }
    }
}

// 计分板
struct ScoreView: View {
    @ObservedObject var game: ReversiGame
    
    var body: some View {
        HStack {
            PlayerScoreView(color: .black, count: game.blackCount)
            Spacer()
            PlayerScoreView(color: .white, count: game.whiteCount)
        }
        .padding()
    }
}

// 单个玩家分数视图
struct PlayerScoreView: View {
    let color: ReversiGame.Piece
    let count: Int
    
    var body: some View {
        VStack {
            Text(color.rawValue)
                .font(.system(size: 30))
            Text("\(count)")
                .font(.title.bold())
        }
        .padding()
        .background(RoundedRectangle(cornerRadius: 10).fill(Color.white))
    }
}

// 棋盘视图
struct BoardView: View {
    @ObservedObject var game: ReversiGame
    
    var body: some View {
        Grid(horizontalSpacing: 0, verticalSpacing: 0) {
            ForEach(0..<8, id: \.self) { row in
                GridRow {
                    ForEach(0..<8, id: \.self) { col in
                        CellView(game: game, row: row, col: col)
                    }
                }
            }
        }
        .border(Color.black, width: 2)
        .background(Color.black)
    }
}

// 单个格子视图
struct CellView: View {
    @ObservedObject var game: ReversiGame
    let row: Int
    let col: Int
    
    var body: some View {
        let isValid = game.isValidMove(row: row, col: col)
        
        ZStack {
            Rectangle()
                .fill(Color.green)
            
            if let piece = game.board[row][col] {
                Text(piece.rawValue)
                    .font(.system(size: 30))
                    .foregroundColor(piece == .black ? .black : .white)
            } else if isValid {
                Circle()
                    .fill(game.currentPlayer == .black ? Color.black.opacity(0.3) : Color.white.opacity(0.3))
                    .frame(width: 15, height: 15)
            }
        }
        .aspectRatio(1, contentMode: .fit)
        .onTapGesture {
            if isValid {
                game.placePiece(row: row, col: col)
            }
        }
    }
}

// 控制面板（竖屏）
struct ControlView: View {
    @ObservedObject var game: ReversiGame
    
    var body: some View {
        VStack {
            Text("当前玩家: \(game.currentPlayer.rawValue)")
                .font(.title2)
            
            Button("重新开始") {
                game.resetGame()
            }
            .buttonStyle(.borderedProminent)
            .padding()
            
            if game.gameOver {
                Text("游戏结束！")
                    .font(.title)
                    .foregroundColor(.red)
            }
        }
    }
}

// 横屏控制面板
struct LandscapeControlView: View {
    @ObservedObject var game: ReversiGame
    
    var body: some View {
        HStack {
            Spacer()
            ControlView(game: game)
                .padding()
                .background(RoundedRectangle(cornerRadius: 10).fill(Color.white.opacity(0.9)))
                .padding()
        }
    }
}

// 预览
#Preview {
    ReversiView()
}
