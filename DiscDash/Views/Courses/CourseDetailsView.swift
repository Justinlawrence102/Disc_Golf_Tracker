//
//  CourseDetailsView.swift
//  OneDisc
//
//  Created by Justin Lawrence on 6/23/24.
//

import SwiftUI
import MapKit
import SwiftData

struct CourseDetailsView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    var course: Course
    @State var showEditCourseSheet: Course?
    @State var showDeleteCourseAlert = false
//   @Query  var courses: [Course]
//    var course: Course {
//        return courses.first!
//    }
//    init(course: Course) {
//        _courses = Query(filter: #Predicate<Course> {  $0.name == "Sample Course" })
//    }
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading) {
                if let image = course.getImage() {
                    Image(uiImage: image)
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(maxWidth: .infinity)
                        .frame(height: 140)
                        .cornerRadius(8)
                }else {
                    Image(systemName: "figure.disc.sports")
                        .frame(height: 140)
                        .frame(maxWidth: .infinity)
                        .foregroundStyle(Color("Teal"))
                        .font(.title)
                        .background(Color("Lime"))
                        .cornerRadius(8)
                }
                CourseDetailsSection(course: course)
//                CourseMapSection(course: course)
                if let topScores = course.getTopScores(modelContext: modelContext), !topScores.isEmpty {
                    Text("Top Scores")
                        .font(.title3.weight(.semibold))
                        .padding(.top, 16)
                        .foregroundStyle(Color("Navy"))
                    TopScoresSection(course: course, topScores: topScores)
                }
            }
            .safeAreaPadding()
        }
        .navigationTitle(course.name)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Menu {
                    Button(action: {
                        showEditCourseSheet = course
                    }) {
                        Label("Edit", systemImage: "pencil")
                            .foregroundColor(.red)
                    }
                    Button(role: .destructive, action: {
                        showDeleteCourseAlert = true
                    }, label: {
                        Label("Delete Course", systemImage: "trash.fill")
                    })
                }
            label: {
                Label("Info", systemImage: "ellipsis")
            }
            }
        }
        .sheet(item: $showEditCourseSheet, content: {_ in 
            CreateCourseDetailsView(course: course, isNewCourse: false, createCourseModalShowing: $showEditCourseSheet)
                .navigationBarTitleDisplayMode(.inline)
        })
        .alert("Delete Course", isPresented: $showDeleteCourseAlert) {
            Button("Delete", role: .destructive) {
                modelContext.delete(course)
                dismiss.callAsFunction()
            }
            Button("Cancel", role: .cancel) { }
        }message: {
            Text("Are you sure you want to delete \(course.name)? Every game at this course will also be deleted.")
        }
    }
}

#Preview {
    NavigationStack {
        CourseDetailsView(course: Course(name: "Test"))
            .modelContainer(GamesPreviewContainer)
    }
}

private struct CourseDetailsSection: View {
    var course: Course
    var body: some View {
        VStack(alignment: .leading, spacing: 4.0) {
            HStack {
                Image(systemName: "location.fill")
                Text(course.cityState ?? "City/State")
                Spacer()
            }
            HStack {
                Image(systemName: "arrow.up.bin.fill")
                Text("\(course.baskets?.count ?? 0) Holes")
            }
            HStack {
                Image(systemName: "clock.badge.checkmark.fill")
                Text("\(course.games?.count ?? 0) Games Played")
            }
            if let latitude = course.latitude, let longitude = course.longitude {
                Button(action: {
                    let url = URL(string: "maps://?saddr=&daddr=\(latitude),\(longitude)")
                    if UIApplication.shared.canOpenURL(url!) {
                        UIApplication.shared.open(url!, options: [:], completionHandler: nil)
                    }
                    
                }, label: {
                    Label("Get Directions", systemImage: "map.fill")
                        .frame(height: 50)
                        .frame(maxWidth: .infinity)
                        .background(Color("Teal"))
                        .cornerRadius(12)
                        .font(.body.weight(.medium))
                        .foregroundStyle(.white)
                        .padding(.horizontal)
                })
                .padding(.top, 16)
            }
        }
        .foregroundStyle(Color("Navy"))
        .padding(12)
        .background(.thinMaterial)
        .cornerRadius(8)
        .frame(maxWidth: .infinity)
    }
}

private struct CourseMapSection: View {
    var course: Course
    
    var sortedBasketsList: [Basket] {
      return (course.baskets ?? []).sorted(by: {$1.number ?? 0 > $0.number ?? 0})
    }
    
    var body: some View {
        Map() {
            ForEach(sortedBasketsList) {
                hole in
                ForEach(hole.teeCoordinates, id: \.self) {
                    teeCoordinate in
                    Marker("", systemImage: "\(hole.number ?? 1).square.fill", coordinate: teeCoordinate)
                        .tint(Color("Teal"))
                    ForEach(hole.basketCoordinates, id: \.self) {
                        basketCoordiante in
                        MapPolyline(points: [MKMapPoint(basketCoordiante), MKMapPoint(teeCoordinate)])
                            .stroke(.tertiary, style: StrokeStyle(lineWidth: 5, lineCap: .round))
                    }
                }
                ForEach(hole.basketCoordinates, id: \.self) {
                    basketCoordinate in
                    Marker("", systemImage: "arrow.up.bin.fill", coordinate: basketCoordinate)
                        .tint(Color("Pink"))
                }
                if let index = sortedBasketsList.firstIndex(of: hole), sortedBasketsList.indices.contains(index+1){
                    if let currentBasket = hole.basketCoordinates.first, let nextTee = sortedBasketsList[index+1].teeCoordinates.first {
                        MapPolyline(points: [MKMapPoint(currentBasket), MKMapPoint(nextTee)])
                            .stroke(.secondary, style: StrokeStyle(lineWidth: 1, lineCap: .round, dash: [3, 5]))
                    }
                }
            }
        }
        .frame(height: 250)
        .cornerRadius(8)
        .disabled(true)
    }
}

struct TopScoresSection: View {
    var course: Course

    var topScores: [ResultScores]
    var body: some View {
        ForEach(topScores) {
            score in
            HStack {
                PlayerProfileCircleView(player: Player(name: score.name, color: score.color, image: score.image), size: 50)
                VStack(alignment: .leading) {
                    Text(score.name)
                        .font(.headline)
                    Text(score.formattedDate)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                .foregroundStyle(Color("Navy"))
                Spacer()
                HStack(alignment: .bottom, spacing: 3.0) {
                    Text(String(score.score))
                        .font(.title3.weight(.semibold))
                        .foregroundStyle(Color("Teal"))
                    Text(String(score.getParDiff(course: course)))
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(Color("Pink"))
                }
                .padding(12)
                .background(.thickMaterial)
                .cornerRadius(6)
            }
            .padding(8)
            .background(score.getColor())
            .cornerRadius(8)
        }
    }
}
