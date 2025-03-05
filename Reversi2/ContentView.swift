//
//  ContentView.swift
//  Reversi2
//
//  Created by Stephen Tim on 2025/2/8.
//
import SwiftUI
import AudioToolbox

enum Piece: Equatable {
    case empty                       // 空，还没下子的
    case black                       // 黑棋子
    case white                       // 白棋子
    
    var opposite: Piece {            // 对手
        switch self {
        case .black: return .white
        case .white: return .black
        case .empty: return .empty
        }
    }
}

enum PlayerType {
    case human, ai1, ai2
    
    var isAI: Bool { self != .human }
}

// MARK: - Model
class ReversiGame: ObservableObject {
    @Published var board: [[Piece]]                     // 棋盘
    @Published var currentPlayer: Piece = .black        // 当前玩家
    @Published var blackPlayerType: PlayerType = .human // 黑色玩家类型
    @Published var whitePlayerType: PlayerType = .human // 白色玩家类型
    @Published var gameOver = false                     // 游戏结束
    @Published var emptyCells = 0                       // 空格子数
    @Published var blackScore = 0                       // 黑方分数（棋子数）
    @Published var whiteScore = 0                       // 白方分数（棋子数）
    @Published var aiEnabled = true                     // 允许AI
    @Published var aiThinking = false                   // AI在思考
//    private let aiPlayer: Piece = .white                // 设置AI执白棋
    
    // 位置权重表
    private let positionWeights: [[Int]] = [
        [100, -20, 10,  5,  5, 10, -20, 100],
        [-20, -50, -2, -2, -2, -2, -50, -20],
        [ 10,  -2, -1, -1, -1, -1,  -2,  10],
        [  5,  -2, -1, -1, -1, -1,  -2,   5],
        [  5,  -2, -1, -1, -1, -1,  -2,   5],
        [ 10,  -2, -1, -1, -1, -1,  -2,  10],
        [-20, -50, -2, -2, -2, -2, -50, -20],
        [100, -20, 10,  5,  5, 10, -20, 100]]
    
    init() {
        board = Array(repeating: Array(repeating: .empty, count: 8), count: 8)
        board[3][3] = .white
        board[3][4] = .black
        board[4][3] = .black
        board[4][4] = .white
        updateScores()
    }
    
    // 更新分数
    func updateScores() {
        emptyCells = board.flatMap { $0 }.filter { $0 == .empty }.count    // 更新空格子数
        blackScore = board.flatMap { $0 }.filter { $0 == .black }.count    // 更新黑方分数
        whiteScore = board.flatMap { $0 }.filter { $0 == .white }.count    // 更新白方分数
    }
    
    // 指定点是否在棋盘内
    func isWithinBounds(row: Int, col: Int) -> Bool {
        return row >= 0 && row < 8 && col >= 0 && col < 8
    }
    
    // 在指定的棋盘中，这个玩家落这个棋子是否合法
    private func isValidDrop(row: Int, col: Int, board: [[Piece?]], player: Piece) -> Bool {
        // 修改原有验证逻辑支持指定棋盘和玩家
        // 空格才能下
        guard board[row][col] == .empty else { return false }
        
        // 对手
        let opponent = player.opposite
        // 8个方向
        let directions = [(-1, -1), (-1, 0), (-1, 1),
                          ( 0, -1),          ( 0, 1),
                          ( 1, -1),  (1, 0), ( 1, 1)]
        
        // 逐个方向进行判断
        for direction in directions {
            var x = row + direction.0
            var y = col + direction.1
            var foundOpponent = false
            
            while isWithinBounds(row: x, col: y) {
                let cell = board[x][y]
                if cell == opponent {
                    // 如果发现对手，就做标记，继续沿着同一个方向找下一个进行判断
                    foundOpponent = true
                } else if cell == player {
                    // 如果找到自己之前找到对手，说明这个方向可以，直接
                    if foundOpponent { return true }
                    // 否则 这个方向不行 结束这个方向的判断，继续下一个方向
                    break
                } else {
                    // 如果是空白 这个方向不行 结束这个方向的判断，继续下一个方向
                    break
                }
                x += direction.0
                y += direction.1
            }
        }
        return false
    }
    
    
    // 是否合法的落子
    func isValidDrop(row: Int, col: Int, player: Piece) -> Bool {
        // 空格才能下
        guard board[row][col] == .empty else { return false }
        
        // 对手
        let opponent = player.opposite
        // 8个方向
        let directions = [(-1, -1), (-1, 0), (-1, 1),
                          ( 0, -1),          ( 0, 1),
                          ( 1, -1),  (1, 0), ( 1, 1)]
        
        // 逐个方向进行判断
        for direction in directions {
            var x = row + direction.0
            var y = col + direction.1
            var foundOpponent = false
            
            while isWithinBounds(row: x, col: y) {
                let cell = board[x][y]
                if cell == opponent {
                    // 如果发现对手，就做标记，继续沿着同一个方向找下一个进行判断
                    foundOpponent = true
                } else if cell == player {
                    // 如果找到自己之前找到对手，说明这个方向可以，直接
                    if foundOpponent { return true }
                    // 否则 这个方向不行 结束这个方向的判断，继续下一个方向
                    break
                } else {
                    // 如果是空白 这个方向不行 结束这个方向的判断，继续下一个方向
                    break
                }
                x += direction.0
                y += direction.1
            }
        }
        return false
    }
    
    // 落1个子
    func dropOnePiece(row: Int, col: Int) {
        guard isValidDrop(row: row, col: col, player: currentPlayer) else { return }   // 如果不合法，不能在这里落子
        
        board[row][col] = currentPlayer // 下子
        AudioServicesPlaySystemSound(1001) // 音效
        
        let opponent = currentPlayer.opposite
        let directions = [(-1, -1), (-1, 0), (-1, 1),
                          ( 0, -1),          ( 0, 1),
                          ( 1, -1),  (1, 0), ( 1, 1)]
        
        // 逐个方向看看有没有可以吃的棋子，有就吃掉它
        for direction in directions {
            var x = row + direction.0
            var y = col + direction.1
            // 用个数组来记录这个方向上紧挨着的对手棋子，有可能可以吃
            var adjacentCellsOfOpponentInOneDirection = [(Int, Int)]()
            
            while isWithinBounds(row: x, col: y) && board[x][y] == opponent {
                // 发现一个就把位置加入到临时数组，再沿着这个方向找下一个，直到不是对手的子
                adjacentCellsOfOpponentInOneDirection.append((x, y))
                x += direction.0
                y += direction.1
            }
            
            // 不是对手的子，有2中情况，自己的子或空白未下的
            if isWithinBounds(row: x, col: y) && board[x][y] == currentPlayer {
                // 全部吃掉 TODO: 这里要不要判断数组是否为空？数组为空的情况是第一颗紧挨着的是自己的子
                for (i, j) in adjacentCellsOfOpponentInOneDirection {
                    board[i][j] = currentPlayer
                }
            }
        }
        
        // 更新分数
        updateScores()
        // 轮到下一个玩家
        currentPlayer = currentPlayer.opposite
        
        // 看看这个玩家能不能下子，如果不能下子有2种情况，1没有可以下的子，就跳过，2下满了，就结束游戏
        // 这个优化流程：当你不能下，我也不能下，就结束，好处在于不用判断是否下满，减少代码量
        if !hasAnyValidDrop(for: currentPlayer) {
            currentPlayer = currentPlayer.opposite
            if !hasAnyValidDrop(for: currentPlayer) {
                gameOver = true
            }
        }
        // 落子后检查是否需要AI移动
        if aiEnabled && currentPlayer == .white && whitePlayerType.isAI {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                self.aiMakeMove()
            }
        }
    }
    
    // 有没有一个可以下的点
    func hasAnyValidDrop(for player: Piece) -> Bool {
        for i in 0..<8 {
            for j in 0..<8 {
                if isValidDrop(row: i, col: j, player: player) {
                    return true
                }
            }
        }
        return false
    }
    
    // 重新开始一局
    func reset() {
        board = Array(repeating: Array(repeating: .empty, count: 8), count: 8)
        board[3][3] = .white
        board[3][4] = .black
        board[4][3] = .black
        board[4][4] = .white
        currentPlayer = .black
        gameOver = false
        updateScores()
    }
    
    // AI决策入口
    func aiMakeMove() {
        guard aiEnabled && currentPlayer == .white && whitePlayerType.isAI else { return }
        aiThinking = true
        
        DispatchQueue.global(qos: .userInitiated).async {
            let bestMove = self.findBestMove(depth: 5)
            
            DispatchQueue.main.async {
                if let move = bestMove {
                    self.dropOnePiece(row: move.row, col: move.col)
                }
                self.aiThinking = false
            }
        }
    }
    
    // 寻找最优下子方案 极大极小算法实现
    private func findBestMove(depth: Int) -> (row: Int, col: Int)? {
        var bestScore = Int.min                // 标记最好分数
        var bestMoves = [(Int, Int)]()         // 标记最好的下子
        
        let validMoves = getAllValidMoves()    // 合法的下子
        if validMoves.isEmpty { return nil }
        
        for move in validMoves {
            let newBoard = simulateDropOnePiece(row: move.0, col: move.1, board: board, player: currentPlayer)
            let score = minimax(board: newBoard, depth: depth - 1, alpha: Int.min, beta: Int.max, isMaximizing: false)
            
            if score > bestScore {
                bestScore = score
                bestMoves = [move]
            } else if score == bestScore {
                bestMoves.append(move)
            }
        }
        
        return bestMoves.randomElement().map { (row: $0.0, col: $0.1) }
    }
    
    // 极大极小算法
    private func minimax(board: [[Piece?]], depth: Int, alpha: Int, beta: Int, isMaximizing: Bool) -> Int {
        if depth == 0 {
            return evaluateBoard(board: board)
        }
        
        let currentColor = isMaximizing ? Piece.white : Piece.black
        let validMoves = getAllValidMoves(for: currentColor, in: board)
        
        if validMoves.isEmpty {
            return evaluateBoard(board: board)
        }
        
        var alpha = alpha
        var beta = beta
        
        if isMaximizing {
            var maxEval = Int.min
            for move in validMoves {
                let newBoard = simulateDropOnePiece(row: move.0, col: move.1, board: board, player: currentColor)
                let eval = minimax(board: newBoard, depth: depth - 1, alpha: alpha, beta: beta, isMaximizing: false)
                maxEval = max(maxEval, eval)
                alpha = max(alpha, eval)
                if beta <= alpha { break }
            }
            return maxEval
        } else {
            var minEval = Int.max
            for move in validMoves {
                let newBoard = simulateDropOnePiece(row: move.0, col: move.1, board: board, player: currentColor)
                let eval = minimax(board: newBoard, depth: depth - 1, alpha: alpha, beta: beta, isMaximizing: true)
                minEval = min(minEval, eval)
                beta = min(beta, eval)
                if beta <= alpha { break }
            }
            return minEval
        }
    }
    
    // 棋盘评估函数
    private func evaluateBoard(board: [[Piece?]]) -> Int {
        var score = 0
        var mobility = 0
        var stability = 0
        
        // 位置权重评估
        for i in 0..<8 {
            for j in 0..<8 {
                guard let piece = board[i][j] else { continue }
                let weight = piece == Piece.white ? positionWeights[i][j] : -positionWeights[i][j]
                score += weight
            }
        }
        
        // 行动力评估
        let aiMoves = getAllValidMoves(for: Piece.white, in: board).count
        let playerMoves = getAllValidMoves(for: Piece.black, in: board).count
        mobility = (aiMoves - playerMoves) * 10
        
        // 稳定子评估（角落）
        let corners = [(0,0), (0,7), (7,0), (7,7)]
        for (i,j) in corners {
            guard let piece = board[i][j] else { continue }
            stability += piece == Piece.white ? 50 : -50
        }
        
        return score + mobility + stability
    }
    
    // 工具方法
    private func getAllValidMoves(for player: Piece? = nil, in board: [[Piece?]]? = nil) -> [(Int, Int)] {
        let currentPlayer = player ?? self.currentPlayer
        let checkBoard = board ?? self.board
        var moves = [(Int, Int)]()
        
        for i in 0..<8 {
            for j in 0..<8 {
                if isValidDrop(row: i, col: j, board: checkBoard, player: currentPlayer) {
                    moves.append((i, j))
                }
            }
        }
        return moves
    }
    
    // 在一个棋盘中落1个子
    // 模拟下这步棋 返回下完这步棋之后的新盘势
    private func simulateDropOnePiece(row: Int, col: Int, board: [[Piece?]], player: Piece) -> [[Piece?]] {
        var newBoard = board
        guard isValidDrop(row: row, col: col, board: newBoard, player: player) else { return newBoard }   // 如果不合法，不能在这里落子
        
        newBoard[row][col] = player // 下子
        //        AudioServicesPlaySystemSound(1001) // 音效
        
        let opponent = player.opposite
        let directions = [(-1, -1), (-1, 0), (-1, 1),
                          ( 0, -1),          ( 0, 1),
                          ( 1, -1),  (1, 0), ( 1, 1)]
        
        // 逐个方向看看有没有可以吃的棋子，有就吃掉它
        for direction in directions {
            var x = row + direction.0
            var y = col + direction.1
            // 用个数组来记录这个方向上紧挨着的对手棋子，有可能可以吃
            var adjacentCellsOfOpponentInOneDirection = [(Int, Int)]()
            
            while isWithinBounds(row: x, col: y) && newBoard[x][y] == opponent {
                // 发现一个就把位置加入到临时数组，再沿着这个方向找下一个，直到不是对手的子
                adjacentCellsOfOpponentInOneDirection.append((x, y))
                x += direction.0
                y += direction.1
            }
            
            // 不是对手的子，有2中情况，自己的子或空白未下的
            if isWithinBounds(row: x, col: y) && newBoard[x][y] == player {
                // 全部吃掉 TODO: 这里要不要判断数组是否为空？数组为空的情况是第一颗紧挨着的是自己的子
                for (i, j) in adjacentCellsOfOpponentInOneDirection {
                    newBoard[i][j] = player
                }
            }
        }
        return newBoard
    }
}

// MARK: - View
struct CellView: View {
    @ObservedObject var game: ReversiGame
    let row: Int
    let col: Int
    
    @State private var flip = false

    var body: some View {
        Group {
            ZStack {
                Rectangle()
                    .fill(Color.green)
                if game.board[row][col] != .empty {
                    Circle()
                        .fill(game.board[row][col] == .black ? Color.black : Color.white)
                        .padding(4)
                        .rotation3DEffect(
                            flip ? .degrees(180) : .zero,
                            axis: (x: 0.0, y: 1.0, z: 0.0)
                        )
                        .onChange(of: game.board[row][col]) { oldValue, newValue in
                            withAnimation(.easeInOut(duration: 0.5)) {
                                flip.toggle()
                            }
                        }
                }
                if game.isValidDrop(row: row, col: col, player: game.currentPlayer) {
                    Circle()
                        .fill((game.currentPlayer == .black ? Color.black : Color.white).opacity(0.6))
                        .padding(18)
                }
            }
            .aspectRatio(1, contentMode: .fit)
        }
        .contentShape(Rectangle()) // 保证点击区域全覆盖
    }
}

// 计分板 竖屏版
struct ScoreView: View {
    @ObservedObject var game: ReversiGame
    
    var body: some View {
        HStack {
            Spacer()
            PlayerScoreView(player: .black, count: game.blackScore, isCurrentPlayer: game.currentPlayer == .black ? true : false)
            Spacer()
            PlayerScoreView(player: .empty, count: game.emptyCells, isCurrentPlayer: false)
            Spacer()
            PlayerScoreView(player: .white, count: game.whiteScore, isCurrentPlayer: game.currentPlayer == .white ? true : false)
            Spacer()
        }
        .padding()
    }
}
// 计分板 横屏版
struct LandscapeScoreView: View {
    @ObservedObject var game: ReversiGame
    
    var body: some View {
        VStack {
            Spacer()
            PlayerScoreView(player: .black, count: game.blackScore, isCurrentPlayer: game.currentPlayer == .black ? true : false)
            Spacer()
            PlayerScoreView(player: .empty, count: game.emptyCells, isCurrentPlayer: false)
            Spacer()
            PlayerScoreView(player: .white, count: game.whiteScore, isCurrentPlayer: game.currentPlayer == .white ? true : false)
            Spacer()
        }
        .padding()
    }
}

// 单个玩家分数视图
struct PlayerScoreView: View {
    let player: Piece
    let count: Int
    let isCurrentPlayer: Bool
    
    var body: some View {
        ZStack {
            Circle()
                .fill(player == .black ? Color.black : player == .white ? Color.white : Color.blue.opacity(0.2))
                .frame(width: 50, height: 50)
                .padding(4)
            Text("\(count)")
                .font(.title.bold())
                .foregroundColor(player == .black ? Color.white : Color.black)
        }
        .padding()
        .background(RoundedRectangle(cornerRadius: 10).fill((isCurrentPlayer ? Color.green : Color.gray).opacity(0.75)))
    }
}

// 控制面板
struct ControlView: View {
    @ObservedObject var game: ReversiGame
    @State private var showResetConfirmation = false

    var body: some View {
        VStack {
            Button("重新开始") {
                if game.gameOver {
                    game.reset()
                } else {
                    showResetConfirmation = true
                }
            }
            .buttonStyle(.borderedProminent)
            .padding()
            .alert("确认重新开始", isPresented: $showResetConfirmation) {
                Button("取消", role: .cancel) {}
                Button("确定", role: .destructive) {
                    game.reset()
                }
            } message: {
                Text("确定要重新开始游戏吗？当前进度将会丢失。")
            }
        }
    }
}
// 信息窗口
struct InfoView: View {
    @ObservedObject var game: ReversiGame

    var body: some View {
        VStack {
            if game.aiThinking {
                ProgressView()
                    .padding()
                Text("AI：让我思考一下...")
                    .font(.caption)
            }
            if game.gameOver {
                Text("游戏结束")
                    .font(.title)
                    .foregroundColor(.blue)
                Text(game.blackScore > game.whiteScore ? "黑方胜" :
                     game.whiteScore > game.blackScore ? "白方胜" : "平局")
                    .font(.title)
                    .foregroundColor(.red)
            }
        }
    }
}


// 棋盘视图
struct BoardView: View {
    @ObservedObject var game: ReversiGame
    
    var body: some View {
        Grid(horizontalSpacing: 1, verticalSpacing: 1) {
            ForEach(0..<8, id: \.self) { row in
                GridRow {
                    ForEach(0..<8, id: \.self) { col in
                        CellView(game: game, row: row, col: col)
                        .border(Color.black, width: 0.5)
                        .onTapGesture {
                            if !game.gameOver {
                                game.dropOnePiece(row: row, col: col)
                            }
                        }
                    }
                }
            }
        }
        .border(Color.black, width: 1)
        .background(Color.black)
    }
}

// 设置视图和AI策略实现
struct PlayerConfigView: View {
    let player: Piece
    @Binding var type: PlayerType
    
    var body: some View {
        VStack {
            Text(player == .black ? "黑色棋手设置：" : "白色棋手设置：")
            Picker("白色棋手设置：", selection: $type) {
                Text("人手").tag(PlayerType.human)
                Text("AI:极大极小+α-β剪枝").tag(PlayerType.ai1)
                Text("AI:蒙特卡洛树").tag(PlayerType.ai2)
            }
            .pickerStyle(SegmentedPickerStyle())
        }
    }
}

// 版本信息
struct copyrightView: View {
    // 计算属性获取版本信息
    var appVersion: String {
        let version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "Unknown"
        let build = Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "Unknown"
        return "Version \(version) (Build \(build))"
    }
    var body: some View {
        Text("设计者：Tim@博学堂\n版本号：\(appVersion)")
            .font(.footnote)
            .foregroundColor(.gray.opacity(0.5))
        .padding()
    }
}

// MARK: - ViewModel
struct ContentView: View {
    @StateObject var game = ReversiGame()

    @State var type: Int = 0
    
    var body: some View {
        GeometryReader { geometry in
            let isPortrait = geometry.size.height > geometry.size.width
            ZStack {
                HStack {
                    Spacer()
                    VStack {
                        Spacer()
                        copyrightView()
                    }
                }
                if isPortrait {
                    // 竖屏版
                    VStack {
                        ControlView(game: game)
                        ScoreView(game: game)
                        BoardView(game: game)
                            .frame(width: min(geometry.size.width, geometry.size.height) * 0.95,
                                   height: min(geometry.size.width, geometry.size.height) * 0.95)
                        PlayerConfigView(player: .white, type: $game.whitePlayerType)
                        Spacer()
                        InfoView(game: game)
                        Spacer()
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .background(Color.green.opacity(0.3))
                } else {
                    // 横屏版
                    HStack {
                        VStack {
                            Spacer()
                            LandscapeScoreView(game: game)
                        }
                        BoardView(game: game)
                            .frame(width: min(geometry.size.width, geometry.size.height) * 0.95,
                                   height: min(geometry.size.width, geometry.size.height) * 0.95)
                        Spacer()
                        VStack {
                            ControlView(game: game)
                            PlayerConfigView(player: .white, type: $game.whitePlayerType)
                            Spacer()
                            InfoView(game: game)
                            Spacer()
                        }
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .background(Color.green.opacity(0.3))
                }
            }
        }
    }
}
