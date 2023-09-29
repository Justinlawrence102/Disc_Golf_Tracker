//
//  SearchCourseView.swift
//  DiscDash
//
//  Created by Justin Lawrence on 9/28/23.
//

import SwiftUI

struct SearchCourseView: View {
    @State var coursesStorage = [ImportedCourses]()

    @State var courses = [ImportedCourses]()
    @State var searchText = ""
    @EnvironmentObject var locationManager: LocationManager

    @Binding var showSearchCoursesSheet: Bool
    @Binding var selectedItem: Course?

    var body: some View {
        List(courses.sorted(by: {$1.getDistance(locationManager: locationManager) ?? 0 > $0.getDistance(locationManager: locationManager) ?? 0})) {
            course in
            HStack {
                VStack(alignment: .leading) {
                    Text(course.name)
                        .font(.headline)
                        .foregroundStyle(Color("Navy"))
                    Text("\(course.city), \(course.state)")
                        .font(.subheadline)
                        .foregroundStyle(Color("Navy"))
                    if let distance = course.getDistance(locationManager: locationManager) {
                        HStack {
                            Image(systemName: "location.fill")
                            Text("\(String(format: "%.1f", distance)) mi")
                        }
                        .foregroundStyle(Color("Teal"))
                            .font(.caption)
                    }
                }
                Spacer()
            }
            .contentShape(Rectangle())
            .onTapGesture {
                showSearchCoursesSheet = false
                selectedItem = course.saveNewCourse()
                print("Tapped")
            }
        }
        .listStyle(.plain)
        .searchable(text: $searchText, placement: .navigationBarDrawer(displayMode: .always))
        .onChange(of: searchText) {
            self.courses = coursesStorage.filter({$0.name.lowercased().contains(searchText.lowercased())})
        }
        .onAppear {
            if let courses = importFromJson(searchString: "") {
                self.courses = courses
                self.coursesStorage = courses
            }
        }
    }
}

func importFromJson(searchString: String) -> [ImportedCourses]? {
    do {
        if let filePath = Bundle.main.path(forResource: "data", ofType: "json") {
            let data = try Data(contentsOf: URL(fileURLWithPath: filePath))
            let results = (try JSONDecoder().decode(ImprtedCoursesResponse.self, from: data)).courses
            return results
        }
    } catch {
        print("error: \(error)")
    }
    return nil
}
//#Preview {
//    NavigationStack {
//        SearchCourseView()
//            .environmentObject(LocationManager())
//    }
//}
