import SwiftUI
import AVKit
import AVFoundation
import CoreText

#if os(iOS)
import UIKit

extension UIDevice {
    static var idiom: UIUserInterfaceIdiom {
        UIDevice.current.userInterfaceIdiom
    }
}
#endif

func registerFont() {
    if let fontURL = Bundle.main.url(forResource: "Hakgyoansim Geurimilgi TTF R", withExtension: "ttf") {
        CTFontManagerRegisterFontsForURL(fontURL as CFURL, .process, nil)
    }
}

class AudioPlayerDelegate: NSObject, AVAudioPlayerDelegate, ObservableObject {
    @Published var isPlayingAudio = false
    
    func audioPlayerDidFinishPlaying(_ player: AVAudioPlayer, successfully flag: Bool) {
        isPlayingAudio = false
    }
}

final class BackgroundMusicManager {
    static let shared = BackgroundMusicManager()
    private var player: AVAudioPlayer?

    func playBackgroundMusic(track: String) {
        guard let url = Bundle.main.url(forResource: track, withExtension: "mp3") else {
            print("Resource not found: \(track).mp3")
            return
        }
        do {
            player = try AVAudioPlayer(contentsOf: url)
            player?.numberOfLoops = -1 // 무한 반복
            player?.volume = 0.04   // 볼륨 조절 (0.0 ~ 1.0)
            player?.play()
        } catch {
            print("Fail to initialize player", error)
        }
    }
    
  
    func stopBackgroundMusic() {
        player?.stop()
    }
}



struct ContentView: View {
    @State private var colors: [Color] = []
    @State private var currentQuestion: String = ""
    @State private var previousQuestion: String? = nil // 추가
    @State private var score = 0
    @State private var showResult = false
    @State private var isCorrect = false
    @State private var selectedColor: Color?
    @State private var player: AVAudioPlayer?
    @State private var questionPlayer: AVAudioPlayer?
    @State private var isPlayingAudio = false
    @State private var trigger = false
    
    @StateObject private var audioDelegate = AudioPlayerDelegate()
    // @State private var player: AVAudioPlayer?
    
    let allColors: [String: Color] = [
        "black": .black,
        "red": .red,
        "yellow": .yellow,
        "pink": .pink,
        "green": .green,
        "purple": .purple,
        "orange": .orange,
   //     "mint": .mint,
    //    "teal": .teal, //청록색
   //     "cyan": .cyan, //옥색
        "blue":    .blue,
     //   "indigo": .indigo,//남색
        "brown": .brown,
        "white":  .white,
        "gray": .gray
        
    ]
    
    var body: some View {
        ZStack {
            VStack {
              /*  Text("Score: \(score)")
                    .font(.title)
                    .padding()
                */
                if !showResult {
                    LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())]) {
                        ForEach(colors, id: \.self) { color in
                            ColorCardView(
                                color: color,
                                isSelected: selectedColor == color,
                                action: {
                                    trigger.toggle()
                                    checkAnswer(selectedColor: color)
                                }
                            ) .sensoryFeedback(.impact(weight: .medium), trigger: trigger)
                        }
                    }
                    .padding()
                } else {
                    ResultView(
                        isCorrect: isCorrect,
                        color: selectedColor ?? .clear,
                        score: score
                    )
                }
                
                if showResult {
                    
                    Button(action: {
                        showResult = false
                        trigger.toggle()
                        loadNewQuestion()
                    }) {
                        Image("blueButton")
                            .resizable()
                        #if os(iOS)
                            .frame(width:   UIDevice.idiom == .phone ? 100 : 200 , height: UIDevice.idiom == .phone ? 100 : 200)
                    #elseif os(macOS)
                            .frame(width:  400 , height: 400)
                    #endif
                          
                          
                    }
                }
                    
            }.disabled(audioDelegate.isPlayingAudio)
                .sensoryFeedback(.impact(weight: .medium), trigger: trigger)
        }
        .onAppear(perform: loadNewQuestion)
        .onAppear {
                BackgroundMusicManager.shared.playBackgroundMusic(track: "WaltzForYou") // 파일명만!
            }
            .onDisappear {
                BackgroundMusicManager.shared.stopBackgroundMusic()
            }
    }
    
  /*  func loadNewQuestion() {
           // 이전 문제와 다른 질문이 나올 때까지 반복
           var questionColor: String
           repeat {
               questionColor = allColors.keys.randomElement()!
           } while questionColor == previousQuestion && allColors.keys.count > 1
           
           previousQuestion = currentQuestion
           currentQuestion = questionColor
           
           var newColors = [allColors[questionColor]!]
           while newColors.count < 4 {
               if let randomColor = allColors.values.randomElement(), !newColors.contains(randomColor) {
                   newColors.append(randomColor)
               }
           }
           colors = newColors.shuffled()
           
           playSound(named: questionColor)
           resetState()
       }
    
    */
    func loadNewQuestion() {
        // 1. 이전 질문을 제외한 색상 목록 생성
        let availableQuestions = allColors.keys.filter { $0 != previousQuestion }
        
        // 2. 새로운 질문 선택 (필터링된 배열이 비었을 경우 전체에서 선택)
        let questionColor = availableQuestions.isEmpty
            ? allColors.keys.randomElement()!
            : availableQuestions.randomElement()!
        
        // 3. 상태 업데이트
        previousQuestion = currentQuestion
        currentQuestion = questionColor
        
        // 4. 색상 카드 생성
        var newColors = [allColors[questionColor]!]
        while newColors.count < 4 {
            if let randomColor = allColors.values.randomElement(), !newColors.contains(randomColor) {
                newColors.append(randomColor)
            }
        }
        colors = newColors.shuffled()
        
        // 5. 사운드 재생 및 상태 초기화
        playSound(named: questionColor)
        resetState()
    }

    func checkAnswer(selectedColor: Color) {
        self.selectedColor = selectedColor
        let correctColor = allColors[currentQuestion]!
        isCorrect = selectedColor == correctColor
        
        if isCorrect {
            score += 10
            playSound(named: "correctAnswer")
        } else {
            score = max(0, score - 5)
            playSound(named: "wrongAnswer")
        }
        
        withAnimation(.easeInOut(duration: 0.3)) {
            showResult = true
        }
    }
    
    func resetState() {
        withAnimation {
            showResult = false
            selectedColor = nil
        }
    }
    
    /*  func playSound(named: String) {
     guard let url = Bundle.main.url(forResource: named, withExtension: "mp3") else { return }
     
     do {
     let player = try AVAudioPlayer(contentsOf: url)
     player.play()
     if named == currentQuestion {
     questionPlayer = player
     } else {
     self.player = player
     }
     } catch {
     print("Error playing sound: \(error)")
     }
     }
     } */
    
    func playSound(named: String) {
        guard let url = Bundle.main.url(forResource: named, withExtension: "mp3") else { return }
        do {
            let newPlayer = try AVAudioPlayer(contentsOf: url)
            newPlayer.delegate = audioDelegate
            newPlayer.play()
            audioDelegate.isPlayingAudio = true
            self.player = newPlayer
        } catch {
            print("Error playing sound: \(error)")
            audioDelegate.isPlayingAudio = false
        }
    }
    
}
    
    

struct ColorCardView: View {
    let color: Color
    let isSelected: Bool
    let action: () -> Void
  
    
    var body: some View {
        Button(action: action) {
          
            RoundedRectangle(cornerRadius: 20)
                .fill(color)
                .stroke(Color.white, lineWidth: 4)
                .aspectRatio(1, contentMode: .fit)
                .scaleEffect(isSelected ? 1.1 : 1.0)
                .animation(.easeInOut, value: isSelected)
        }
    }
}

    struct ResultView: View {
        let isCorrect: Bool
        let color: Color
        let score: Int
        
        var body: some View {
            ZStack {
                Color(color)
                    .ignoresSafeArea()
                
                VStack {
                  /*  RoundedRectangle(cornerRadius: 5)
                        .frame (width: isCorrect ? 230 : 150, height: 50)
                        .overlay(
                    Text(isCorrect ? "그래 참 잘했다!" : "아닌데!")
                    //    .font(.largeTitle)
                        .font(.custom("Hakgyoansim Geurimilgi TTF R", size:30))
                        .bold()
                        .foregroundColor(isCorrect ? .green : .red)
                      //  .background(isCorrect ? .red  : .green)
                        .padding()
                        .cornerRadius(10)
                    ) */
                    Image(isCorrect ? "correctAnswer" : "wrongAnswer")
                        .resizable()
                        .scaledToFit()
                    
                    #if os(iOS)
                        .frame(width:   UIDevice.idiom == .phone ? 250 : 400 , height: UIDevice.idiom == .phone ? 250 : 400)
                    #elseif os(macOS)
                        .frame(width:  400 , height: 400)
                    #endif
                        .cornerRadius(20)
                    
                    
                 /*   RoundedRectangle(cornerRadius: 20)
                        .fill(color)
                        .frame(width: 200, height: 200)
                    
                    */
                    Text(" \(color)")
                        .font(.title2)
                }
                .transition(.scale)
            }
        }
}


#Preview {
    ContentView()
}
