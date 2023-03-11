//
//  MealView.swift
//  Fetch-Meal
//
//  Created by Pavan Sai Nallagoni on 3/10/23.
//

import SwiftUI

struct Meal: Codable {
    let id: String
    let name: String
    let thumbnail: String?
    let strIngredients: String?
    
    var ingredientsList: [Ingredient] {
        guard let strIngredients = strIngredients else {
            return []
        }
        let ingredients = strIngredients.split(separator: ",")
            .map { String($0.trimmingCharacters(in: .whitespacesAndNewlines)) }
        return ingredients.map { Ingredient(name: $0, measurement: "") }
    }
    
    enum CodingKeys: String, CodingKey {
        case id = "idMeal"
        case name = "strMeal"
        case thumbnail = "strMealThumb"
        case strIngredients
    }
}

struct Ingredient: Codable {
    let name: String
    let measurement: String
}

struct MealsResult: Codable {
    let meals: [Meal]
}


struct MealDetailsResult: Codable {
    let meals: [Meal]
}

class MealsManager: ObservableObject {
    @Published var meals: [Meal] = []
    
    func fetchMeals() {
        guard let url = URL(string: "https://themealdb.com/api/json/v1/1/filter.php?c=Dessert") else {
            return
        }
        
        URLSession.shared.dataTask(with: url) { data, response, error in
            guard let data = data, error == nil else {
                print("Failed to fetch meals: \(error?.localizedDescription ?? "Unknown error")")
                return
            }
            
            do {
                let result = try JSONDecoder().decode(MealsResult.self, from: data)
                DispatchQueue.main.async {
                    self.meals = result.meals
                }
            } catch {
                print("Failed to decode meals: \(error.localizedDescription)")
            }
        }.resume()
    }
    
    func fetchMealDetails(id: String, completion: @escaping (Result<Meal, Error>) -> Void) {
        let urlString = "https://www.themealdb.com/api/json/v1/1/lookup.php?i=\(id)"
        guard let url = URL(string: urlString) else { return }
        
        URLSession.shared.dataTask(with: url) { data, _, error in
            if let error = error {
                completion(.failure(error))
                return
            }
            
            guard let data = data else {
                completion(.failure(NSError(domain: "fetchMealDetails", code: -1, userInfo: [NSLocalizedDescriptionKey: "Data not found"])))
                return
            }
            
            do {
                let result = try JSONDecoder().decode(MealDetailsResult.self, from: data)
                guard let meal = result.meals.first else {
                    completion(.failure(NSError(domain: "fetchMealDetails", code: -1, userInfo: [NSLocalizedDescriptionKey: "Meal not found"])))
                    return
                }
                completion(.success(meal))
            } catch {
                completion(.failure(error))
            }
        }.resume()
    }
    
    
    func updateMeal(_ updatedMeal: Meal) {
        if let index = self.meals.firstIndex(where: { $0.id == updatedMeal.id }) {
            self.meals[index] = updatedMeal
        }
    }
}

struct MealListView: View {
    @StateObject var mealsManager = MealsManager()
    
    var body: some View {
        NavigationView {
            List(mealsManager.meals, id: \.id) { meal in
                NavigationLink(destination: MealDetailsView(mealId: meal.id, mealsManager: mealsManager)) {
                    HStack {
                        if let thumbnailUrl = meal.thumbnail,
                           let url = URL(string: thumbnailUrl) {
                            AsyncImage(url: url) { image in
                                image
                                    .resizable()
                                    .scaledToFit()
                                    .frame(width: 100, height: 100)
                            } placeholder: {
                                Rectangle()
                                    .foregroundColor(.gray)
                                    .frame(width: 100, height: 100)
                            }
                        } else {
                            Rectangle()
                                .foregroundColor(.gray)
                                .frame(width: 100, height: 100)
                        }
                        Text(meal.name)
                    }
                }
            }
            .navigationTitle("Desserts")
        }
        .onAppear {
            mealsManager.fetchMeals()
        }
    }
}

struct MealDetailsView: View {
    let mealId: String
    @ObservedObject var mealsManager: MealsManager
    @State var meal: Meal?
    
    var body: some View {
        VStack {
            if let meal = meal {
                if let thumbnailUrl = meal.thumbnail,
                   let url = URL(string: thumbnailUrl),
                   let imageData = try? Data(contentsOf: url),
                   let image = UIImage(data: imageData) {
                    Image(uiImage: image)
                        .resizable()
                        .scaledToFit()
                        .frame(maxWidth: .infinity)
                }
                Text(meal.name)
                    .font(.title)
                    .padding()
                List(meal.ingredientsList, id: \.name) { ingredient in
                    HStack {
                        Text(ingredient.name)
                        Spacer()
                        Text(ingredient.measurement)
                    }
                }
                .padding()
            } else {
                Text("Loading...")
            }
        }
        .navigationTitle("Meal Details")
        .onAppear {
            mealsManager.fetchMealDetails(id: mealId) { result in
                switch result {
                case .success(let meal):
                    self.meal = meal
                case .failure(let error):
                    print("Failed to fetch meal details: \(error.localizedDescription)")
                }
            }
        }
    }
}
