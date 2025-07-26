//
//  EditProfileImageView.swift
//  OneDisc
//
//  Created by Justin Lawrence on 7/26/25.
//

import SwiftUI

struct EditProfileImageView: View {
    @Binding var model: RemoveImageBackgroundModel
    
    @Binding var player: Player
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 12) {
                ZStack {
                    Image(uiImage: model.image ?? UIImage())
                        .resizable()
                        .scaledToFit()
                        .frame(width: 300, height: 300)
                    if model.isLoading {
                        ProgressView()
                            .tint(.white)
                    }
                }
                
                Button(action:{
                    model.createSticker()
                }, label: {
                    Label("Remove Background", systemImage: "wand.and.sparkles")
                        .padding(12)
                        .background(.teal)
                        .clipShape(Capsule())
                        .foregroundStyle(.white)
                })
            }
            .navigationTitle("Edit Image")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing, content: {
                    Button(action: {
                        player.image = model.image?.pngData()!
                        model.showEditProfileSheet = false
                    }, label: {
                        Image(systemName: "checkmark")
                    })
                    .buttonStyle(.glassProminent)
                    .tint(.teal)
                })
            }
        }
    }
}

struct EditProfileImageView_Previews: PreviewProvider {

    static var previews: some View {
        @State var player = Player(name: "Justin", color: "")
        @State var model = RemoveImageBackgroundModel(image: UIImage(named: "dad")!)
        EditProfileImageView(model: $model, player: $player)
    }
}

