//
//  AddPlacesFirebaseScript.swift
//  NearBy
//
//  Created by Ace of Heart on 2026-03-29.
//

import Foundation
import FirebaseFirestore

func seedMontrealPlaces() {
    let db = Firestore.firestore()
    let placesCollection = db.collection("places")
    
    let montrealData: [Place] = [
//        // MARK: - RESTAURANTS
//        Place(name: "Schwartz's Deli", category: "restaurants", address: "3895 St Laurent Blvd", latitude: 45.5163, longitude: -73.5776, rating: 4.5, phone: "(514) 842-4813"),
//        Place(name: "Joe Beef", category: "restaurants", address: "2491 Notre-Dame St W", latitude: 45.4831, longitude: -73.5753, rating: 4.7, phone: "(514) 935-6504"),
//        Place(name: "L'Express", category: "restaurants", address: "3927 Saint Denis St", latitude: 45.5191, longitude: -73.5768, rating: 4.6, phone: "(514) 845-5333"),
//        Place(name: "Damas", category: "restaurants", address: "1201 Van Horne Ave", latitude: 45.5224, longitude: -73.6128, rating: 4.8, phone: "(514) 439-5435"),
//        Place(name: "Cochon Dingue", category: "restaurants", address: "46 Rue Saint-Louis", latitude: 46.8122, longitude: -71.2062, rating: 4.4, phone: "(418) 692-2013"),
//        Place(name: "Bouillon Bilk", category: "restaurants", address: "1595 St Laurent Blvd", latitude: 45.5103, longitude: -73.5658, rating: 4.7, phone: "(514) 842-0393"),
//        Place(name: "Montreal Pool Room", category: "restaurants", address: "1217 St Laurent Blvd", latitude: 45.5085, longitude: -73.5629, rating: 4.1, phone: "(514) 954-4487"),
//        Place(name: "Gibeau Orange Julep", category: "restaurants", address: "7700 Decarie Blvd", latitude: 45.4951, longitude: -73.6565, rating: 4.3, phone: "(514) 738-7050"),
//        Place(name: "Mandy's Salads", category: "restaurants", address: "201 Laurier Ave W", latitude: 45.5204, longitude: -73.5955, rating: 4.5, phone: "(514) 419-5144"),
//        Place(name: "Jun I", category: "restaurants", address: "156 Laurier Ave W", latitude: 45.5201, longitude: -73.5950, rating: 4.6, phone: "(514) 276-5864"),
//        Place(name: "Kazu", category: "restaurants", address: "1862 Saint-Catherine St W", latitude: 45.4929, longitude: -73.5807, rating: 4.7, phone: "(514) 937-2333"),
//        Place(name: "Le Filet", category: "restaurants", address: "219 Mont-Royal Ave W", latitude: 45.5199, longitude: -73.5912, rating: 4.6, phone: "(514) 360-6060"),
//
//        // MARK: - CAFES
//        Place(name: "Crew Collective", category: "cafes", address: "360 St Jacques St", latitude: 45.5015, longitude: -73.5591, rating: 4.7, phone: "(514) 285-8886"),
//        Place(name: "Café Olympico", category: "cafes", address: "124 Saint-Viateur St W", latitude: 45.5241, longitude: -73.6017, rating: 4.7, phone: "(514) 495-0746"),
//        Place(name: "Tommy Café", category: "cafes", address: "200 Notre-Dame St W", latitude: 45.5034, longitude: -73.5566, rating: 4.4, phone: "(514) 903-8666"),
//        Place(name: "Café Myriade", category: "cafes", address: "1432 Mackay St", latitude: 45.4965, longitude: -73.5791, rating: 4.5, phone: "(514) 939-1717"),
//        Place(name: "Dispatch Coffee", category: "cafes", address: "267 Saint-Zotique St W", latitude: 45.5318, longitude: -73.6145, rating: 4.5, phone: "(514) 439-4404"),
//        Place(name: "Café Saint-Henri", category: "cafes", address: "3632 Notre-Dame St W", latitude: 45.4795, longitude: -73.5835, rating: 4.5, phone: "(514) 507-9539"),
//        Place(name: "Café ORR", category: "cafes", address: "5368 Park Ave", latitude: 45.5201, longitude: -73.5939, rating: 4.6, phone: "(514) 270-2233"),
//        Place(name: "Café Chat L'Heureux", category: "cafes", address: "172 Duluth Ave E", latitude: 45.5189, longitude: -73.5759, rating: 4.5, phone: "(514) 303-9996"),
//        Place(name: "Café Chato", category: "cafes", address: "4833 Verdun St", latitude: 45.4595, longitude: -73.5714, rating: 4.8, phone: "(514) 762-2222"),
//        Place(name: "Le Darling", category: "cafes", address: "4328 St Laurent Blvd", latitude: 45.5197, longitude: -73.5824, rating: 4.4, phone: "(514) 303-1561"),
//        Place(name: "Leaves House", category: "cafes", address: "2051 De la Montagne St", latitude: 45.4988, longitude: -73.5772, rating: 4.6),
//        Place(name: "Caffettiera Caffe Bar", category: "cafes", address: "2055 Stanley St", latitude: 45.5012, longitude: -73.5750, rating: 4.7),
//        Place(name: "Paquebot Mont-Royal", category: "cafes", address: "2110 Mont-Royal Ave E", latitude: 45.5342, longitude: -73.5684, rating: 4.6),
////        Place(name: "Pikolo Espresso Bar", category: "cafes", address: "3418 Park Ave", latitude: 45.5074, longitude: -73.5744, rating: 4.6),
////        Place(name: "Cafe Replika", category: "cafes", address: "252 Rachel St E", latitude: 45.5202, longitude: -73.5815, rating: 4.6),
////        Place(name: "Canard Café", category: "cafes", address: "4351 Ontario St E", latitude: 45.5488, longitude: -73.5415, rating: 4.5),
////        Place(name: "Cafe OSMO", category: "cafes", address: "51 Sherbrooke St W", latitude: 45.5134, longitude: -73.5711, rating: 4.5),
//
//        // MARK: - PARKS
//        Place(name: "Maisonneuve Park", category: "Parks", address: "4601 Sherbrooke St E", latitude: 45.5594, longitude: -73.5553, rating: 4.5),
//        Place(name: "Parc Jarry", category: "Parks", address: "205 Gary-Carter St", latitude: 45.5348, longitude: -73.6288, rating: 4.6),
//        Place(name: "Lachine Canal Park", category: "Parks", address: "Saint-Patrick St", latitude: 45.4791, longitude: -73.5714, rating: 4.7),
//        Place(name: "Parc Westmount", category: "Parks", address: "Sherbrooke St W", latitude: 45.4795, longitude: -73.5972, rating: 4.7),
//        Place(name: "Parc Laurier", category: "Parks", address: "735 Laurier Ave E", latitude: 45.5303, longitude: -73.5866, rating: 4.6),
//        Place(name: "Parc Angrignon", category: "Parks", address: "3400 Trinitaires Blvd", latitude: 45.4428, longitude: -73.6019, rating: 4.5),
//        Place(name: "Parc Sir-Wilfrid-Laurier", category: "Parks", address: "5225 Berri St", latitude: 45.5302, longitude: -73.5862, rating: 4.6),
//        Place(name: "Square Victoria", category: "Parks", address: "Square Victoria", latitude: 45.5015, longitude: -73.5620, rating: 4.4),
//        Place(name: "Parc de Dieppe", category: "Parks", address: "3400 Pierre-Dupuy Ave", latitude: 45.5011, longitude: -73.5398, rating: 4.7),
//        Place(name: "Parc de la Petite-Italie", category: "Parks", address: "St Laurent Blvd", latitude: 45.5347, longitude: -73.6139, rating: 4.5),
//        Place(name: "Parc Molson", category: "Parks", address: "Beaubien St E", latitude: 45.5457, longitude: -73.5912, rating: 4.6),
//        Place(name: "Morgan Park", category: "Parks", address: "Ste-Catherine St E", latitude: 45.5414, longitude: -73.5412, rating: 4.4),
//
//        // MARK: - SHOPPING
//        Place(name: "Eaton Centre", category: "Shopping", address: "705 Saint-Catherine St W", latitude: 45.5020, longitude: -73.5714, rating: 4.4),
//        Place(name: "Place Ville Marie", category: "Shopping", address: "1 Place Ville Marie", latitude: 45.5009, longitude: -73.5683, rating: 4.3),
//        Place(name: "Montreal Trust", category: "Shopping", address: "1500 McGill College Ave", latitude: 45.5011, longitude: -73.5724, rating: 4.3),
//        Place(name: "Holt Renfrew Ogilvy", category: "Shopping", address: "1307 Sherbrooke St W", latitude: 45.4988, longitude: -73.5779, rating: 4.5),
//        Place(name: "Complexe Desjardins", category: "Shopping", address: "150 Saint-Catherine St W", latitude: 45.5075, longitude: -73.5638, rating: 4.3),
//        Place(name: "Marché Atwater", category: "Shopping", address: "138 Atwater Ave", latitude: 45.4795, longitude: -73.5771, rating: 4.7),
//        Place(name: "Marché Jean-Talon", category: "Shopping", address: "7070 Henri Julien Ave", latitude: 45.5358, longitude: -73.6146, rating: 4.7),
//        Place(name: "Rockland Centre", category: "Shopping", address: "2305 Rockland MD", latitude: 45.5255, longitude: -73.6475, rating: 4.4),
//        Place(name: "Premium Outlets Montreal", category: "Shopping", address: "19001 Chemin Notre-Dame", latitude: 45.6802, longitude: -73.9103, rating: 4.3),
//        Place(name: "Place Alexis Nihon", category: "Shopping", address: "1500 Atwater Ave", latitude: 45.4897, longitude: -73.5833, rating: 4.1),
//        Place(name: "Promenade Masson", category: "Shopping", address: "Masson St", latitude: 45.5422, longitude: -73.5786, rating: 4.4),
//        Place(name: "Plaza St-Hubert", category: "Shopping", address: "St-Hubert St", latitude: 45.5377, longitude: -73.6033, rating: 4.2),
//        Place(name: "Marché Bonsecours", category: "Shopping", address: "350 Saint-Paul St E", latitude: 45.5094, longitude: -73.5515, rating: 4.2),
//        Place(name: "Quartier DIX30", category: "Shopping", address: "9160 Leduc Blvd", latitude: 45.4444, longitude: -73.4402, rating: 4.4),
//        Place(name: "CF Galeries d'Anjou", category: "Shopping", address: "7999 Galeries d'Anjou Blvd", latitude: 45.5929, longitude: -73.5604, rating: 4.3),
        Place(name: "Grande Bibliothèque", category: "Libraries", address: "475 De Maisonneuve Blvd E", latitude: 45.5156, longitude: -73.5624, rating: 4.6),
        Place(name: "Westmount Public Library", category: "Libraries", address: "4574 Sherbrooke St W", latitude: 45.4795, longitude: -73.5972, rating: 4.8),
        Place(name: "Atwater Library", category: "Libraries", address: "1200 Atwater Ave", latitude: 45.4889, longitude: -73.5855, rating: 4.5),
        Place(name: "Bibliothèque Frontenac", category: "Libraries", address: "2551 Ontario St E", latitude: 45.5342, longitude: -73.5521, rating: 4.3),
        Place(name: "Bibliothèque Marc-Favreau", category: "Libraries", address: "500 Rosemont Blvd", latitude: 45.5323, longitude: -73.5972, rating: 4.7),
        Place(name: "Bibliothèque de Verdun", category: "Libraries", address: "5955 Bannantyne Ave", latitude: 45.4519, longitude: -73.5830, rating: 4.4),
        Place(name: "Bibliothèque de Saul-Bellow", category: "Libraries", address: "3100 Saint-Antoine St", latitude: 45.4377, longitude: -73.6702, rating: 4.3),
        Place(name: "Bibliothèque Benny", category: "Libraries", address: "6400 Monkland Ave", latitude: 45.4673, longitude: -73.6302, rating: 4.6),
        Place(name: "Bibliothèque Saint-Henri", category: "Libraries", address: "4707 Notre-Dame St W", latitude: 45.4719, longitude: -73.5898, rating: 4.3),
        Place(name: "Bibliothèque Mordecai-Richler", category: "Libraries", address: "5434 Park Ave", latitude: 45.5204, longitude: -73.5947, rating: 4.5),

        // MARK: - EDUCATION
        Place(name: "Université de Montréal", category: "Education", address: "2900 Edouard Montpetit Blvd", latitude: 45.5019, longitude: -73.6129, rating: 4.6),
        Place(name: "UQAM", category: "Education", address: "405 Saint-Catherine St E", latitude: 45.5132, longitude: -73.5606, rating: 4.2),
        Place(name: "HEC Montréal", category: "Education", address: "3000 Chemin de la Côte-Sainte-Catherine", latitude: 45.5034, longitude: -73.6213, rating: 4.5),
        Place(name: "Polytechnique Montréal", category: "Education", address: "2500 Chemin de Polytechnique", latitude: 45.5045, longitude: -73.6146, rating: 4.5),
        Place(name: "Dawson College", category: "Education", address: "3040 Sherbrooke St W", latitude: 45.4896, longitude: -73.5885, rating: 4.3),
        Place(name: "Vanier College", category: "Education", address: "821 Saint-Croix Blvd", latitude: 45.5156, longitude: -73.6749, rating: 4.2),
        Place(name: "Marianopolis College", category: "Education", address: "4873 Westmount Ave", latitude: 45.4886, longitude: -73.6053, rating: 4.4),
        Place(name: "Collège Jean-de-Brébeuf", category: "Education", address: "3200 Chemin de la Côte-Sainte-Catherine", latitude: 45.5011, longitude: -73.6247, rating: 4.6),
        Place(name: "Cegep du Vieux Montreal", category: "Education", address: "255 Ontario St E", latitude: 45.5144, longitude: -73.5658, rating: 4.1),
        Place(name: "Cegep Marie-Victorin", category: "Education", address: "7000 Maurice-Duplessis Blvd", latitude: 45.6152, longitude: -73.6067, rating: 4.0),

        // MARK: - ENTERTAINMENT
        Place(name: "Place des Arts", category: "Entertainment", address: "175 Saint-Catherine St W", latitude: 45.5089, longitude: -73.5653, rating: 4.7),
        Place(name: "Casino de Montréal", category: "Entertainment", address: "1 Ave du Casino", latitude: 45.5058, longitude: -73.5255, rating: 4.4),
        Place(name: "Biosphere", category: "Entertainment", address: "160 Ch. Tour-de-l'Isle", latitude: 45.5140, longitude: -73.5315, rating: 4.4),
        Place(name: "Old Port of Montreal", category: "Entertainment", address: "333 Rue de la Commune O", latitude: 45.5042, longitude: -73.5492, rating: 4.7),
        Place(name: "Montreal Science Centre", category: "Entertainment", address: "2 de la Commune St W", latitude: 45.5050, longitude: -73.5510, rating: 4.5),
        Place(name: "Montreal Museum of Fine Arts", category: "Entertainment", address: "1380 Sherbrooke St W", latitude: 45.4986, longitude: -73.5802, rating: 4.7),
        Place(name: "McCord Museum", category: "Entertainment", address: "690 Sherbrooke St W", latitude: 45.5045, longitude: -73.5739, rating: 4.5),
        Place(name: "The Montreal Tower", category: "Entertainment", address: "3200 Viau St", latitude: 45.5583, longitude: -73.5532, rating: 4.3),
        Place(name: "Pointe-à-Callière Museum", category: "Entertainment", address: "350 Place Royale", latitude: 45.5031, longitude: -73.5539, rating: 4.7),
        Place(name: "Society for Arts and Technology", category: "Entertainment", address: "1201 St Laurent Blvd", latitude: 45.5085, longitude: -73.5629, rating: 4.5),
        Place(name: "Théâtre Saint-Denis", category: "Entertainment", address: "1594 Saint Denis St", latitude: 45.5152, longitude: -73.5619, rating: 4.4),
        Place(name: "Corona Theatre", category: "Entertainment", address: "2490 Notre-Dame St W", latitude: 45.4831, longitude: -73.5786, rating: 4.6)
    ]
    
    for place in montrealData {
        do {
            _ = try placesCollection.addDocument(from: place)
            print("Successfully added: \(place.name)")
        } catch {
            print("Error uploading \(place.name): \(error.localizedDescription)")
        }
    }
}
