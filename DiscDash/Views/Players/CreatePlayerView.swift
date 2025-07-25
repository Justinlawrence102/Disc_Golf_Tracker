//
//  CreatePlayerView.swift
//  Disc Golf Tracker
//
//  Created by Justin Lawrence on 8/31/23.
//

import Foundation
import SwiftUI
import PhotosUI
import SwiftData
import Contacts

struct CreatePlayerView: View {
    @Environment(\.modelContext) private var playerContext
    @Environment(\.dismiss) private var dismiss
    @State var player: Player
    @State var showContactsSheet = false
    @State var selectedContact = CNContact()
    var isNewPerson: Bool

    var playerColors: [String] = [ "C7F465", "FE6B6B", "4ECDC4", "58636D", "059EDF", "F2F2F7", "FF003D", "FF9900", "FDD608", "00AE26", "0906A7", "6507AE" ]
    @State private var selectedImage: PhotosPickerItem?


    var items: [GridItem] {
        Array(repeating: .init(.adaptive(minimum: 120)), count: playerColors.count/2)
    }
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading) {
                    ZStack {
                        PlayerProfileCircleView(player: player, size: 80)
                    }
                    .padding(.top)
                    .frame(maxWidth: .infinity)
                    TextField(
                           "Name",
                           text: $player.name
                       )
                    .textInputAutocapitalization(.words)
                    .multilineTextAlignment(.center)
                    .padding()
                    .background(Color(UIColor.secondarySystemBackground))
                    .foregroundStyle(Color("Navy"))
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                    .padding([.leading, .bottom, .trailing])

                    
                    Text("Photo")
                        .font(.title2)
                        .fontWeight(.semibold)
                        .foregroundStyle(Color("Navy"))
                    ScrollView(.horizontal) {
                        HStack(spacing: 12.0){
                            PhotosPicker(selection: $selectedImage, matching: .images) {
                                Image(systemName: "camera.fill")
                                    .frame(width: 75, height: 75)
                                    .background(Color("Teal"))
                                    .cornerRadius(37.5)
                                    .tint(.white)
                                    .font(.title)
                            }
                            .onChange(of: selectedImage) {
                                old, new in
                                Task {
                                    if let selectedImage = selectedImage, let data = try? await selectedImage.loadTransferable(type: Data.self) {
                                        if let uiImage = UIImage(data: data) {
                                            if let compressed = resizeImage(image: uiImage, maxSize: 150) {
                                                player.image = compressed.pngData()!
                                            }
//                                            player.image = uiImage.jpegData(compressionQuality: 0.5)
                                        }
                                    }
                                }
                            }
                        
                            Button(action: {
                                let pasteboard = UIPasteboard.general
                                if let uiImage = pasteboard.image {
                                    if let compressed = resizeImage(image: uiImage, maxSize: 150) {
                                        player.image = compressed.pngData()!
                                    }
//                                    player.image = image.jpegData(compressionQuality: 0.5)
                                }
                                print("Tapped Clipbard")
                            }, label: {
                                Image(systemName: "doc.on.clipboard")
                                    .frame(width: 75, height: 75)
                                    .background(Color("Teal"))
                                    .cornerRadius(37.5)
                                    .tint(.white)
                                    .font(.title)
                            })
                            Button(action: {
                                print("Tapped Contacts")
                                showContactsSheet.toggle()
                            }, label: {
                                Image(systemName: "person.crop.circle.fill")
                                    .frame(width: 75, height: 75)
                                    .background(Color("Teal"))
                                    .cornerRadius(37.5)
                                    .tint(.white)
                                    .font(.title)
                            })
                            
//                            Button(action: {
//                                print("Tapped Memoji")
//                            }, label: {
//                                Text("😀")
//                                    .font(.system(size: 35))
//                                    .frame(width: 75, height: 75)
//                                    .background(Color("Teal"))
//                                    .cornerRadius(37.5)
//                            })
                        }
                    }
                    Text("Color")
                        .font(.title2)
                        .fontWeight(.semibold)
                        .foregroundStyle(Color("Navy"))

                    LazyVGrid(columns: items) {
                        ForEach(playerColors, id: \.self) { color in
                            Button(action: {
                                player.color = color
                            }, label: {
                                ZStack {
                                    if player.color == color {
                                        Circle()
                                            .foregroundStyle(Color(UIColor.systemGray3))
                                            .cornerRadius(25)
                                            .frame(width: 55)
                                    }
                                    Circle()
                                        .frame(width: 45)
                                        .foregroundStyle(Color(UIColor(hex: color)!))
                                }
                                .frame(height: 55)
                            })
                        }
                    }
                    Spacer()
                }
                .scrollClipDisabled(true)
                .padding([.leading, .bottom, .trailing], 12.0)
            }
            .navigationTitle("New Player")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading, content: {
                    Button(action: {
                        dismiss.callAsFunction()
                    }, label: {
                        Image(systemName: "xmark")
                    })
                    .tint(.primary)
                })
                
                ToolbarItem(placement: .topBarTrailing, content: {
                    Button(action: {
                        if isNewPerson {
                            playerContext.insert(player)
                            player.scores = []
                        }else {
                            do {
                                try playerContext.save()
                            }catch {print("Could not save")}
                        }
                        dismiss.callAsFunction()
                    }, label: {
                        Image(systemName: "checkmark")
                    })
                    .buttonStyle(.glassProminent)
                    .tint(.teal)
                })
            }
        }
        .sheet(isPresented: $showContactsSheet) {
            EmbeddedContactPicker(contact: $selectedContact)
//            CNContactViewControllerRepresentable(contact: $selectedContact)
                .edgesIgnoringSafeArea(.all)
        }
        .onChange(of: selectedContact) {
            if let image = selectedContact.thumbnailImageData {
                player.image = image
            }
        }
    }
}


#Preview {
    CreatePlayerView(player: Player(), isNewPerson: true)
}
