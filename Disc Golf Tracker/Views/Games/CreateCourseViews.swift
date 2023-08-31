//
//  CreateGamesViews.swift
//  Disc Golf Tracker
//
//  Created by Justin Lawrence on 8/29/23.
//

import Foundation
import SwiftUI
import SwiftData
import PhotosUI
import MapKit

struct CreateCourseDetailsView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) var dismiss

    @State var course = Course()
    @State private var selectedItem: PhotosPickerItem?
    var isNewCourse = false
    
    var body: some View {
        NavigationStack {
            Form {
                TextField("Name", text: $course.name, prompt: Text("Course Name"))
                    .foregroundStyle(Color("Navy"))
                
                ZStack {
                    //when the map is added, the nav title becomes black for some reason?
                    Map(initialPosition: .region(course.getInitailMapPosition()))
                        .onMapCameraChange { context in
                            course.latitude = context.region.center.latitude
                            course.longitude = context.region.center.longitude
                            course.lookUpCurrentLocation()
                        }
                        .mapStyle(.standard(elevation: .realistic))
                        .frame(height: 200)
                        .cornerRadius(12)
//
                    Image(systemName: "mappin")
                        .shadow(color: .blue, radius: 12)
                        .foregroundStyle(.red)
                        .font(.title)
                }
                VStack {
                    PhotosPicker(selection: $selectedItem, matching: .images) {
                        HStack {
                            Text("Photo")
                                .foregroundStyle(Color("Navy"))
                            Spacer()
                            Image(systemName: "camera.fill")
                        }
                    }
                    .onChange(of: selectedItem, initial: false, {
                        Task {
                            if let data = try? await selectedItem?.loadTransferable(type: Data.self) {
                                course.image = data
                            }
                        }
                    })
                    if let courseImage = course.image, let image = UIImage(data: courseImage) {
                        Image(uiImage: image)
                            .resizable()
                            .frame(height: 200)
                            .cornerRadius(10)
                    }
                }
            }
            .navigationTitle( isNewCourse ? "Create Course" : "Edit Course")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    NavigationLink {
                        CreateCourseBasketListView(course: course, isNewCourse: isNewCourse)
                            .onAppear() {
                                if isNewCourse {
                                    modelContext.insert(course)
                                    course.baskets = []
                                    course.games = []
                                }
                            }
                    }label: {
                        HStack {
                            Text("Next")
                            Image(systemName: "chevron.right")
                        }
                    }
                }
                ToolbarItem(placement: .cancellationAction, content: {
                    Button(action: {
                        dismiss.callAsFunction()
                    }, label: {
                        Text("Cancel")
                    })
                })
            }
        }
        .tint(Color("Teal"))
    }
}

struct CreateCourseBasketListView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) var dismiss

    @State var course = Course()
    var isNewCourse: Bool

    var body: some View {
        VStack {
            Button(action: {
                let newBasket = Basket(number: (course.baskets ?? []).count + 1, course: course)
                course.baskets?.append(newBasket)
                modelContext.insert(newBasket)
    
            }, label: {
                Label("New Basket", systemImage: "plus")
                    .foregroundColor(.white)
                    .frame(width: 350, height: 50)
                    .background(Color("Teal"))
                    .cornerRadius(12)
            })
            List((course.baskets ?? []).sorted { $1.number > $0.number}) {
                basket in
                Section{
                    BasketDetailRow(basket: basket)
                }

            }
            .listSectionSpacing(16)
        }
        .background(Color.clear)
        .toolbar {
            ToolbarItem(placement: .confirmationAction, content: {
                Button(action: {
                    do {
                        try modelContext.save()
                    }catch {print("Could not save")}
                    dismiss.callAsFunction()
                }, label: {
                    Text(isNewCourse ? "Save" : "Update")
                })
            })
        }
        .navigationTitle(course.name)
        .tint(Color("Teal"))
    }
}

struct BasketDetailRow: View {
    @State var basket: Basket
    var body: some View {
        VStack {
            HStack {
                Text(String("Hole \(basket.number)"))
                    .font(.headline)
                    .foregroundColor(Color("Pink"))
                Spacer()
            }
            HStack(spacing: 12) {
                VStack(alignment: .leading){
                    TextField("Par", text: $basket.par, prompt: Text("Par"))
                        .foregroundStyle(Color("Navy"))
                        .font(.title3)
                        .fontWeight(.semibold)
                        .fontDesign(.rounded)
                        .multilineTextAlignment(.center)
                        .frame(width: 85, height: 50)
                        .background(Color(UIColor.secondarySystemFill))
                        .cornerRadius(12)
                    Text("Par")
                        .font(.subheadline)
                        .foregroundStyle(Color("Teal"))
                }
                Spacer()
                VStack(alignment: .leading){
                    TextField("Disntance (Yards)", text: $basket.distance, prompt: Text("Distance"))
                        .foregroundStyle(Color("Navy"))
                        .font(.title3)
                        .fontWeight(.semibold)
                        .fontDesign(.rounded)
                        .multilineTextAlignment(.center)
                        .frame(width: 85, height: 50)
                        .background(Color(UIColor.secondarySystemFill))
                        .cornerRadius(12)
                    Text("Distance (Yds)")
                        .font(.subheadline)
                        .foregroundStyle(Color("Teal"))
                }
            }
            .padding(.horizontal, 8)
        }
    }
}

#Preview {
//    let course = Course(name: "Sample")
//    CreateCourseDetailsView(course: course)
    CreateCourseDetailsView()
        .modelContainer(CoursePreviewContainer)
}
