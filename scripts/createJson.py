import json
import csv


data = {"courses": [] }

courses = []

with open('courses.csv') as csv_file:
    csv_reader = csv.reader(csv_file, delimiter=',')
#    parkIds = [1116]

    for course in csv_reader:
      data2 = 'https://www.logrideapp.com/addhaunt?id='+str(course[0])
      courseItem = {
      "uuid": course[0],
      "name": course[1],
      "city": course[2],
      "state": course[3],
      "numHoles": int(course[4]),
      "latitude": float(course[5]),
      "longitude": float(course[6])
      }
      courses.append(courseItem)

    data["courses"] = courses
  # print(data["courses"])

with open('data.json', 'a') as f:
    f.write(json.dumps(data, ensure_ascii=False, indent=4))