import SwiftUI
import AVFoundation

// MARK: - KONTEN UTAMA
struct ContentView: View {
    @AppStorage("BestScore") private var bestScore = 0
    @AppStorage("BestStreak") private var bestStreak = 0
    
    enum GameState { case menu, playing }
    @State private var gameState: GameState = .menu
    
    let screenWidth = UIScreen.main.bounds.width
    let screenHeight = UIScreen.main.bounds.height
    
    @State private var showCredits = false
    @State private var showTutorial = false
    @State private var showExitConfirm = false
    @State private var showGameOver = false
    
    @State private var score = 0
    @State private var lives = 3
    @State private var streak = 0
    @State private var sessionBestStreak = 0
    @State private var currentEmoji = "❓"
    
    @State private var timeRemaining: CGFloat = 1.0
    @State private var maxTimePerRound: Double = 15.0
    @State private var timerRunning = false
    @State private var showFeedback = false
    @State private var feedbackIsCorrect = true
    @State private var wrongAnswerShake = 0
    
    @State private var logoScale: CGFloat = 1.0
    @State private var confettiParticles: [ConfettiParticle] = []
    @State private var leaves: [FallingLeaf] = []
    @State private var showConfetti = false
    
    @State private var currentFact = ""
    let ecoFacts = [
        "Glass bottles take 4,000 years to decompose!",
        "Recycling one can saves enough energy to run a TV for 3 hours.",
        "Plastic bags kill over 100,000 marine animals every year.",
        "Paper can be recycled 5 to 7 times before it degrades.",
        "Organic waste in landfills creates Methane, a harmful gas.",
        "Up to 60% of the rubbish that ends up in the dustbin could be recycled.",
        "Recycling plastic takes 88% less energy than raw materials."
    ]
    
    let organicItems = ["🍎", "🍌", "🦴", "🍂", "🥬", "🥖", "🥚", "🍗", "🥀", "💩", "🍉", "🌽", "🥥", "🍄", "🍋", "🥦", "🥐", "🥯", "🥞", "🍟", "🍕", "🌭", "🍔", "🍖", "🍤", "🍣", "🍱", "🍛", "🍙", "🍘", "🍢", "🍡", "🍧", "🍩", "🍪", "🥜", "🧀", "🥩", "🥓", "🥘", "🥑", "🥒", "🥕", "🥔", "🍆", "🍅", "🥝", "🍇", "🍈", "🍊", "🥨", "🥣", "🥗", "🥘", "🍝", "🍜", "🍲", "🦞", "🦑", "🐙", "🍰", "🧁", "🥧", "🍫", "🍬", "🍭", "🍯", "🥛", "🧋", "☕️"]
    let recycleItems = ["🥤", "📰", "📦", "🧴", "🥫", "📒", "👕", "👠", "🚲", "📱", "🔋", "💿", "🔭", "🛍️", "📎", "🧸", "🖇️", "📏", "📐", "✂️", "🖊️", "🌂", "👓", "🕶️", "🧳", "☂️", "🧢", "🎩", "🎓", "👑", "💍", "💄", "💎", "🔨", "🔧", "🪛", "🔩", "⚙️", "⏰", "💻", "⌨️", "🖥️", "🖨️", "🖱️", "📷", "📹", "📺", "📻", "🔦", "💡", "🔌", "🗑️", "🛢️", "🗞️", "📑", "🏷️", "🧱", "🪞", "🪟", "🥄", "🍴", "🥢", "🧂", "🥡", "🥃", "🍷", "🥂", "🍺", "🏺"]
    
    let timer = Timer.publish(every: 0.05, on: .main, in: .common).autoconnect()
    
    var body: some View {
        ZStack {
            getBackgroundColor().edgesIgnoringSafeArea(.all).animation(.linear(duration: 0.5), value: streak)
            
            if !showExitConfirm && !showGameOver && !showTutorial && !showCredits {
                ForEach(leaves) { leaf in
                    Image(systemName: "leaf.fill")
                        .foregroundColor(.white.opacity(leaf.opacity))
                        .scaleEffect(leaf.scale)
                        .position(x: leaf.x, y: leaf.y)
                }
            }
            
            if showConfetti { ForEach(confettiParticles) { p in Circle().fill(p.color).frame(width: 8, height: 8).position(x: p.x, y: p.y) } }
            
            VStack {
                if gameState == .menu {
                    VStack {
                        HStack(spacing: 15) {
                            Spacer()
                            Button(action: { SoundManager.shared.playSFX(soundName: "button", fileExtension: "m4a"); withAnimation { showTutorial = true } }) {
                                Image(systemName: "questionmark.circle.fill").font(.system(size: 35)).foregroundColor(.white.opacity(0.9)).shadow(radius: 2)
                            }
                            Button(action: { SoundManager.shared.playSFX(soundName: "button", fileExtension: "m4a"); withAnimation { showCredits = true } }) {
                                Image(systemName: "info.circle.fill").font(.system(size: 35)).foregroundColor(.white.opacity(0.9)).shadow(radius: 2)
                            }
                        }.padding(.horizontal, 30).padding(.top, 20)
                        
                        Spacer()
                        VStack(spacing: 20) {
                            Text("🌱").font(.system(size: 100)).scaleEffect(logoScale).onAppear { startFallingLeaves(); withAnimation(.easeInOut(duration: 1.5).repeatForever(autoreverses: true)) { logoScale = 1.1 } }
                            Text("EcoSort").font(.system(size: 60, weight: .heavy, design: .rounded)).foregroundColor(.white).shadow(radius: 5)
                            Button(action: startGame) { Text("TAP TO START").font(.title3).bold().foregroundColor(.natureGreen).padding(.horizontal, 50).padding(.vertical, 20).background(Color.white).cornerRadius(30).shadow(radius: 10) }.padding(.top, 20)
                        }
                        Spacer()
                        
                        VStack(spacing: 5) {
                            Text("Best Streak: \(bestStreak) 🔥")
                                .font(.title2)
                                .bold()
                                .foregroundColor(.white)
                                .shadow(radius: 2)
                        }.padding(.bottom, 60)
                        
                    }.transition(.opacity)
                } else {
                    VStack {
                        HStack {
                            Button(action: { SoundManager.shared.playSFX(soundName: "button", fileExtension: "m4a"); timerRunning = false; withAnimation { showExitConfirm = true } }) {
                                Image(systemName: "xmark.circle.fill").font(.system(size: 40)).foregroundColor(.white).shadow(radius: 3)
                            }
                            Spacer()
                            HStack(spacing: 5) { ForEach(0..<3, id: \.self) { i in Image(systemName: "heart.fill").foregroundColor(i < lives ? .red : .black.opacity(0.3)).font(.title2) } }
                            .padding(.horizontal, 20).padding(.vertical, 10).background(Capsule().fill(Color.black.opacity(0.3)))
                            Spacer()
                            VStack(alignment: .center, spacing: 0) {
                                Text("SCORE").font(.caption).bold().foregroundColor(.white.opacity(0.9))
                                Text("\(score)").font(.title).fontWeight(.heavy).foregroundColor(.white).contentTransition(.numericText(value: Double(score)))
                            }.frame(minWidth: 80).padding(.horizontal, 15).padding(.vertical, 8).background(Capsule().fill(Color.black.opacity(0.3)))
                        }.padding(.horizontal, 20).padding(.top, 50)
                        
                        
                        GeometryReader { geo in
                            ZStack(alignment: .leading) {
                                Capsule()
                                    .frame(width: geo.size.width, height: 10)
                                    .foregroundColor(.black.opacity(0.1))
                                Capsule()
                                    .frame(width: max(0, geo.size.width * timeRemaining), height: 10)
                                    .foregroundColor(timeRemaining > 0.4 ? .white : .red)
                                    .animation(.linear(duration: 0.1), value: timeRemaining)
                            }
                        }
                        .frame(height: 10)
                        .padding(.horizontal, 30)
                        .padding(.top, 10)
                        
                        Spacer()
                        
                        ZStack {
                            RoundedRectangle(cornerRadius: 35).fill(Color.white).frame(width: 300, height: 360).shadow(color: Color.black.opacity(0.15), radius: 20, y: 10)
                            Text(currentEmoji).font(.system(size: 150)).transition(.scale.combined(with: .opacity)).id(currentEmoji)
                            if showFeedback { Image(systemName: feedbackIsCorrect ? "checkmark.circle.fill" : "xmark.circle.fill").font(.system(size: 80)).foregroundColor(feedbackIsCorrect ? .green : .red).background(Circle().fill(Color.white)).transition(.scale) }
                            if streak > 1 { VStack(spacing: 0) { Text("\(streak)x").font(.system(size: 40, weight: .black)).foregroundColor(.yellow); Text("COMBO").font(.system(size: 12, weight: .bold)).foregroundColor(.white) }.padding(10).background(Capsule().fill(Color.black.opacity(0.6))).rotationEffect(.degrees(10)).offset(x: 130, y: -60).transition(.scale) }
                        }.modifier(Shake(animatableData: CGFloat(wrongAnswerShake)))
                        
                        Spacer()
                        
                        HStack(spacing: 25) {
                            Button(action: { checkAnswer(isOrganic: true) }) {
                                VStack(spacing: 5) { Image(systemName: "leaf.fill").font(.system(size: 40)); Text("ORGANIC").font(.title3).fontWeight(.heavy) }
                                .frame(maxWidth: .infinity).frame(height: 130).background(Color.darkForest).foregroundColor(.white).cornerRadius(30).shadow(radius: 8, y: 6)
                            }
                            Button(action: { checkAnswer(isOrganic: false) }) {
                                VStack(spacing: 5) { Image(systemName: "arrow.triangle.2.circlepath").font(.system(size: 40)); Text("RECYCLE").font(.title3).fontWeight(.heavy) }
                                .frame(maxWidth: .infinity).frame(height: 130).background(Color.oceanBlue).foregroundColor(.white).cornerRadius(30).shadow(radius: 8, y: 6)
                            }
                        }.padding(.horizontal, 30).padding(.bottom, 60).disabled(!timerRunning)
                    }
                }
            }.blur(radius: (showTutorial || showCredits || showGameOver || showExitConfirm) ? 15 : 0)
            
            // MARK: - POPUP TUTORIAL
            if showTutorial {
                Color.black.opacity(0.6).edgesIgnoringSafeArea(.all).onTapGesture {
                    SoundManager.shared.playSFX(soundName: "button", fileExtension: "m4a"); withAnimation { showTutorial = false }
                }
                
                VStack(spacing: 0) {
                    Text("How to Play EcoSort").font(.system(size: 32, weight: .heavy)).foregroundColor(.oceanBlue).padding(.top, 30).padding(.bottom, 10)
                    
                    ScrollView(showsIndicators: false) {
                        VStack(alignment: .leading, spacing: 35) {
                            HStack(alignment: .top, spacing: 20) {
                                Text("🎯").font(.system(size: 50))
                                VStack(alignment: .leading, spacing: 8) { Text("The Goal").font(.title3).bold().foregroundColor(.darkText); Text("Sort the falling items into the correct bin before the time runs out!").font(.body).foregroundColor(.gray).fixedSize(horizontal: false, vertical: true) }
                            }
                            HStack(alignment: .top, spacing: 20) {
                                VStack(spacing: 12) { Image(systemName: "leaf.fill").foregroundColor(.natureGreen).font(.system(size: 35)); Image(systemName: "arrow.triangle.2.circlepath").foregroundColor(.oceanBlue).font(.system(size: 35)) }.frame(width: 50)
                                VStack(alignment: .leading, spacing: 8) { Text("How to Sort").font(.title3).bold().foregroundColor(.darkText); Text("Tap ORGANIC for natural waste (like 🍎, 🍂, 🦴).").font(.body).foregroundColor(.gray); Text("Tap RECYCLE for manufactured waste (like 🥤, 📦, 📱).").font(.body).foregroundColor(.gray) }
                            }
                            HStack(alignment: .top, spacing: 20) {
                                VStack(spacing: 10) { Capsule().fill(Color.gray.opacity(0.4)).frame(width: 50, height: 8); HStack(spacing: 3) { ForEach(0..<3, id: \.self) { _ in Image(systemName: "heart.fill").foregroundColor(.red).font(.system(size: 14)) } } }.frame(width: 50).padding(.top, 10)
                                VStack(alignment: .leading, spacing: 8) { Text("Timer & Lives").font(.title3).bold().foregroundColor(.darkText); Text("Watch the white bar at the top. If it empties, or if you guess wrong, you lose a life (❤️). 3 mistakes = Game Over!").font(.body).foregroundColor(.gray).fixedSize(horizontal: false, vertical: true) }
                            }
                            HStack(alignment: .top, spacing: 20) {
                                ZStack { RoundedRectangle(cornerRadius: 12).fill(Color.white).frame(width: 55, height: 55).shadow(radius: 3); Text("📻").font(.system(size: 30)); VStack(spacing: 0) { Text("3x").font(.system(size: 11, weight: .black)).foregroundColor(.yellow); Text("COMBO").font(.system(size: 6, weight: .bold)).foregroundColor(.white) }.padding(4).background(Capsule().fill(Color.black.opacity(0.8))).offset(x: 20, y: -20) }.frame(width: 55).padding(.top, 10)
                                VStack(alignment: .leading, spacing: 8) { Text("Combo Multiplier").font(.title3).bold().foregroundColor(.darkText); Text("Get correct answers in a row to activate the COMBO multiplier for a much higher score!").font(.body).foregroundColor(.gray).fixedSize(horizontal: false, vertical: true) }
                            }
                        }.padding(35)
                    }
                    
                    Button(action: { SoundManager.shared.playSFX(soundName: "button", fileExtension: "m4a"); withAnimation { showTutorial = false } }) {
                        Text("GOT IT!").font(.title2).bold().foregroundColor(.white).padding().frame(width: 200, height: 60).background(Capsule().fill(Color.natureGreen)).shadow(radius: 5)
                    }.padding(.bottom, 30)
                }
                .frame(width: 600, height: 550)
                .background(Color.white)
                .cornerRadius(35)
                .shadow(radius: 20)
                .transition(.scale)
                .zIndex(3)
            }
            
            // MARK: - POPUP CREDITS
            if showCredits {
                Color.black.opacity(0.4).edgesIgnoringSafeArea(.all).onTapGesture { SoundManager.shared.playSFX(soundName: "button", fileExtension: "m4a"); withAnimation { showCredits = false } }
                VStack(spacing: 20) {
                    Text("CREDITS").font(.system(size: 34, weight: .heavy)).foregroundColor(.darkForest)
                    
                    VStack(spacing: 15) {
                        Text("Audio & Music").font(.title3).bold().foregroundColor(.darkText)
                        
                        VStack(spacing: 12) {
                            VStack(spacing: 2) {
                                Text("Menu BGM").font(.caption).bold().foregroundColor(.gray)
                                Text("Retro Game Arcade").font(.headline).foregroundColor(.darkText)
                                Text("by moodmode").font(.subheadline).foregroundColor(.oceanBlue)
                            }
                            VStack(spacing: 2) {
                                Text("Game BGM").font(.caption).bold().foregroundColor(.gray)
                                Text("Game Gaming Video Game Music").font(.headline).foregroundColor(.darkText)
                                Text("by ViacheslavStarostin").font(.subheadline).foregroundColor(.oceanBlue)
                            }
                            VStack(spacing: 2) {
                                Text("Button SFX").font(.caption).bold().foregroundColor(.gray)
                                Text("Pop").font(.headline).foregroundColor(.darkText)
                                Text("by DRAGON-STUDIO").font(.subheadline).foregroundColor(.oceanBlue)
                            }
                        }
                    }
                    
                    Divider().padding(.horizontal, 40)
                    
                    VStack(spacing: 15) {
                        Text("Developer").font(.system(size: 34, weight: .heavy)).foregroundColor(.darkForest)
                        
                        VStack(spacing: 2) {
                            Text("Gusti Surya Aditama").font(.headline).foregroundColor(.darkText)
                            Text("Universitas Islam Indonesia").font(.subheadline).foregroundColor(.oceanBlue)
                        }
                    }
                    
                    Button(action: { SoundManager.shared.playSFX(soundName: "button", fileExtension: "m4a"); withAnimation { showCredits = false } }) {
                        Text("BACK").font(.title3).bold().foregroundColor(.white).padding().frame(width: 160, height: 50).background(Capsule().fill(Color.darkForest)).shadow(radius: 5)
                    }.padding(.top, 10)
                }
                .padding(.vertical, 35)
                .frame(width: 550)
                .background(Color.white)
                .cornerRadius(35)
                .padding(.horizontal, 30)
                .shadow(radius: 20)
                .transition(.scale)
                .zIndex(4)
            }
            
            // MARK: - POPUP PAUSE
            if showExitConfirm {
                Color.black.opacity(0.4).edgesIgnoringSafeArea(.all)
                VStack(spacing: 25) {
                    Text("PAUSED").font(.system(size: 34, weight: .heavy)).foregroundColor(.white)
                    VStack(spacing: 20) {
                        Text("Quit Game?").font(.title).bold().foregroundColor(.darkText); Text("Your score will be saved.").font(.body).foregroundColor(.gray)
                        HStack(spacing: 20) {
                            Button(action: { SoundManager.shared.playSFX(soundName: "button", fileExtension: "m4a"); withAnimation { showExitConfirm = false }; timerRunning = true }) { Text("NO").font(.title3).bold().foregroundColor(.gray).padding().frame(width: 110, height: 50).background(Color.gray.opacity(0.2)).cornerRadius(15) }
                            Button(action: { SoundManager.shared.playSFX(soundName: "button", fileExtension: "m4a"); SoundManager.shared.stopBGM(); withAnimation { showExitConfirm = false; if score > bestScore { bestScore = score }; currentFact = ecoFacts.randomElement() ?? "Keep Recyling!"; showGameOver = true } }) { Text("YES").font(.title3).bold().foregroundColor(.white).padding().frame(width: 110, height: 50).background(Color.red).cornerRadius(15) }
                        }
                    }.padding(30).background(Color.white).cornerRadius(30).padding(.horizontal, 30).shadow(radius: 20)
                }.transition(.scale).zIndex(5)
            }
            
            // MARK: - POPUP GAME OVER
            if showGameOver {
                Color.black.opacity(0.4).edgesIgnoringSafeArea(.all)
                VStack(spacing: 25) {
                    Text("GAME OVER").font(.system(size: 40, weight: .heavy)).foregroundColor(.white).shadow(radius: 5)
                    
                    VStack(spacing: 20) {
                        VStack(spacing: 5) {
                            Text("Final Score").font(.system(size: 28, weight: .heavy)).foregroundColor(.darkForest)
                            Text("\(score)").font(.system(size: 80, weight: .heavy)).foregroundColor(.natureGreen)
                        }
                        
                        HStack {
                            VStack(spacing: 2) {
                                Text("Best Score").font(.title3).bold().foregroundColor(.darkForest)
                                Text("\(bestScore)").font(.title).bold().foregroundColor(.darkText)
                            }
                            Spacer()
                            VStack(spacing: 2) {
                                Text("Streak").font(.title3).bold().foregroundColor(.darkForest)
                                Text("\(sessionBestStreak)x").font(.title).bold().foregroundColor(.darkText)
                            }
                            Spacer()
                            VStack(spacing: 2) {
                                Text("Best Streak").font(.title3).bold().foregroundColor(.darkForest)
                                Text("\(bestStreak)x").font(.title).bold().foregroundColor(.darkText)
                            }
                        }.padding(.horizontal, 25)
                        
                        Divider()
                        
                        VStack(spacing: 8) {
                            Text("💡 Eco Fact:").font(.headline).bold().foregroundColor(.orange)
                            Text(currentFact).font(.system(size: 16, weight: .medium)).multilineTextAlignment(.center).foregroundColor(.darkText).padding(.horizontal)
                        }.padding(.vertical, 15).frame(maxWidth: .infinity).background(Color.yellow.opacity(0.15)).cornerRadius(15)
                        
                        HStack(spacing: 15) {
                            Button(action: { SoundManager.shared.playSFX(soundName: "button", fileExtension: "m4a"); withAnimation { gameState = .menu; showGameOver = false } }) {
                                Text("MENU").font(.headline).bold().foregroundColor(.white).padding().frame(height: 55).frame(maxWidth: .infinity).background(Color.gray).cornerRadius(15)
                            }
                            Button(action: { SoundManager.shared.playSFX(soundName: "button", fileExtension: "m4a"); resetGame() }) {
                                Text("PLAY AGAIN").font(.headline).bold().foregroundColor(.white).padding().frame(height: 55).frame(maxWidth: .infinity).background(Color.natureGreen).cornerRadius(15).shadow(radius: 5)
                            }
                        }.padding(.top, 10)
                    }
                    .padding(30)
                    .frame(width: 480)
                    .background(Color.white)
                    .cornerRadius(35)
                    .shadow(radius: 20)
                }.transition(.scale).zIndex(6)
            }
        }
        .onAppear {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                SoundManager.shared.playBGM(soundName: "menu", fileExtension: "m4a")
            }
        }
        .onChange(of: gameState) { _, newState in
            if newState == .menu {
                SoundManager.shared.playBGM(soundName: "menu", fileExtension: "m4a")
            }
        }
        .onReceive(timer) { _ in
            if showConfetti { updateConfetti() }
            if !showExitConfirm && !showGameOver && !showTutorial && !showCredits { updateLeaves() }
            guard gameState == .playing && timerRunning && !showExitConfirm && !showGameOver && !showTutorial && !showCredits else { return }
            if timeRemaining > 0 { timeRemaining -= (0.05 / maxTimePerRound) } else { handleTimeOut() }
        }
    }

    func getBackgroundColor() -> LinearGradient {
        if gameState == .menu { return LinearGradient(colors: [.natureGreen, .natureLime], startPoint: .top, endPoint: .bottom) }
        if streak < 5 { return LinearGradient(colors: [.natureLime, .natureGreen], startPoint: .top, endPoint: .bottom) }
        else if streak < 10 { return LinearGradient(colors: [.cyan, .oceanBlue], startPoint: .top, endPoint: .bottom) }
        else { return LinearGradient(colors: [.yellow, .orange], startPoint: .top, endPoint: .bottom) }
    }

    func checkAnswer(isOrganic: Bool) {
        timerRunning = false
        SoundManager.shared.playSFX(soundName: "button", fileExtension: "m4a")
        let isCorrect = (organicItems.contains(currentEmoji) == isOrganic)
        if isCorrect {
            streak += 1
            if streak > sessionBestStreak { sessionBestStreak = streak }
            if streak > bestStreak { bestStreak = streak }
            
            if streak % 10 == 0 { startConfetti() }
            let multiplier = (streak >= 5) ? 2 : 1
            score += (10 * multiplier)
            if score % 50 == 0 && maxTimePerRound > 2.0 { maxTimePerRound -= 1.0 }
            feedbackIsCorrect = true
        } else {
            withAnimation { wrongAnswerShake += 1 }
            if score > bestScore { bestScore = score }
            streak = 0; lives -= 1
            feedbackIsCorrect = false
            if lives <= 0 { SoundManager.shared.stopBGM(); currentFact = ecoFacts.randomElement()!; withAnimation { showGameOver = true }; return }
        }
        showFeedback = true
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { showFeedback = false; nextItem() }
    }
    
    func startGame() {
        SoundManager.shared.playSFX(soundName: "button", fileExtension: "m4a")
        SoundManager.shared.playBGM(soundName: "game", fileExtension: "m4a")
        score = 0
        lives = 3
        streak = 0
        sessionBestStreak = 0
        maxTimePerRound = 15.0
        nextItem()
        withAnimation { gameState = .playing }
    }
    
    func nextItem() { let all = organicItems + recycleItems; withAnimation(.spring()) { currentEmoji = all.randomElement() ?? "❓"; timeRemaining = 1.0 }; timerRunning = true }
    func handleTimeOut() { checkAnswer(isOrganic: !organicItems.contains(currentEmoji)) }
    func resetGame() { withAnimation { showGameOver = false }; startGame() }
    
    func startFallingLeaves() { if leaves.isEmpty { for _ in 0..<35 { leaves.append(FallingLeaf(x: CGFloat.random(in: 0...screenWidth), y: CGFloat.random(in: 0...screenHeight), scale: CGFloat.random(in: 0.5...1.2), opacity: Double.random(in: 0.3...0.7))) } } }
    func updateLeaves() { for i in leaves.indices { leaves[i].y += 5.0; if leaves[i].y > screenHeight + 50 { leaves[i].y = -50; leaves[i].x = CGFloat.random(in: 0...screenWidth) } } }
    func startConfetti() { showConfetti = true; for _ in 0..<50 { confettiParticles.append(ConfettiParticle(x: CGFloat.random(in: 0...screenWidth), y: -50, color: [.red, .blue, .yellow].randomElement()!, rotation: Double.random(in: 0...360))) }; DispatchQueue.main.asyncAfter(deadline: .now()+2) { showConfetti=false; confettiParticles.removeAll() } }
    func updateConfetti() { for i in confettiParticles.indices { confettiParticles[i].y += 10; confettiParticles[i].rotation += 5 } }
}
