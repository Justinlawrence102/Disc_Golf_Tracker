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
    @Environment(\.dismiss) private var dismiss

    @State var course = Course()
    @State private var selectedPhotoItem: PhotosPickerItem?
    
    @Binding var createCourseModalShowing: Course?
    
    var isNewCourse = false
    
    init(course: Course, isNewCourse: Bool, createCourseModalShowing: Binding<Course?>?) {
        self.course = course
        self.isNewCourse = isNewCourse
        self._createCourseModalShowing = createCourseModalShowing ?? Binding.constant(nil)
    }
    
    var body: some View {
        VStack {
            Form {
                TextField("Name", text: $course.name, prompt: Text("Course Name"))
                    .foregroundStyle(Color("Navy"))
                    .textInputAutocapitalization(.words)
                
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
                    PhotosPicker(selection: $selectedPhotoItem, matching: .images) {
                        HStack {
                            Text("Photo")
                                .foregroundStyle(Color("Navy"))
                            Spacer()
                            Image(systemName: "camera.fill")
                            Button(action: {
                                course.image = nil
                            }, label: {
                                Image(systemName: "xmark")
                                    .foregroundStyle(Color("Pink"))
                            })
                        }
                    }
                    .onChange(of: selectedPhotoItem, initial: false, {
                        Task {
                            if let data = try? await selectedPhotoItem?.loadTransferable(type: Data.self) {
                                if let uiImage = UIImage(data: data) {
                                    if let compressedData = uiImage.jpegData(compressionQuality: 0) {
                                        course.image = compressedData
                                    }
                                }
                                //                                course.image = data
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
        }
        .background(Color(UIColor.systemGroupedBackground))
        .navigationTitle( isNewCourse ? "Create Course" : "Edit Course")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                NavigationLink {
                    CreateCourseBasketListView(course: course, createCourseModalShowing: $createCourseModalShowing, isNewCourse: isNewCourse)
                }label: {
                    HStack {
                        Text("Next")
                        Image(systemName: "chevron.right")
                    }
                }
            }
        }
    }
}

struct CreateCourseBasketListView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) var dismiss

    @State var course = Course()
    @Binding var createCourseModalShowing: Course?
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
            List((course.baskets ?? []).sorted { $1.number ?? 0 > $0.number ?? 0}) {
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
                    print("Save!")
                    if (createCourseModalShowing != nil) {
                        createCourseModalShowing = nil
                    }
                    dismiss.callAsFunction()
                }, label: {
                    Text(isNewCourse ? "Save" : "Update")
                })
            })
        }
        .onAppear(){
            if isNewCourse {
                modelContext.insert(course)
                if course.baskets == nil {
                    course.baskets = []
                }
                course.games = []
            }
        }
        .navigationTitle(course.name)
        .tint(Color("Teal"))
    }
}

struct BasketDetailRow: View {
    @State var basket: Basket
    var body: some View {
        VStack {
            if let number = basket.number {
                HStack {
                    Text(String("Hole \(number)"))
                        .font(.headline)
                        .foregroundColor(Color("Pink"))
                    Spacer()
                }
            }
            HStack(spacing: 12) {
                VStack(alignment: .leading){
                    TextField("Par", text: $basket.par, prompt: Text("Par"))
                        .keyboardType(.numberPad)
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
                    TextField("Disntance (\(Locale.current.measurementSystem == .us ? "Ft" : "M"))", text: $basket.distance, prompt: Text("Distance"))
                        .keyboardType(.numberPad)
                        .foregroundStyle(Color("Navy"))
                        .font(.title3)
                        .fontWeight(.semibold)
                        .fontDesign(.rounded)
                        .multilineTextAlignment(.center)
                        .frame(width: 85, height: 50)
                        .background(Color(UIColor.secondarySystemFill))
                        .cornerRadius(12)
                    Text("Distance (\(Locale.current.measurementSystem == .us ? "Ft" : "M"))")
                        .font(.subheadline)
                        .foregroundStyle(Color("Teal"))
                }
            }
            .padding(.horizontal, 8)
        }
    }
}

//#Preview {
////    let course = Course(name: "Sample")
////    CreateCourseDetailsView(course: course)
////    CreateCourseDetailsView()
////        .modelContainer(CoursePreviewContainer)
//}
