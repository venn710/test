//
//  ContentView.swift
//  TestApp
//
//  Created by Pavan Baradi on 24/07/24.
//

import Combine
import SwiftUI

struct ContentView: View {
    @StateObject var viewModel = ContentViewModel()
    var body: some View {
        VStack {
            Image(systemName: "globe")
                .imageScale(.large)
                .foregroundStyle(.tint)
            Text("Hello, world!")
            if let todo = viewModel.todo {
                VStack {
                    Text(todo.title)
                    Text(String(todo.id))
                    Text(String(todo.userId))
                }
            }
        }
        .padding()
        .task {
            viewModel.getData()
        }
        .alert(viewModel.alertMessage, isPresented: $viewModel.showAlert, actions: {})
    }
}

class ContentViewModel: ObservableObject {
    
    @Published var todo: ToDo?
    @Published var showAlert: Bool = false
    @Published var alertMessage: String = ""
    
    var cancelSet: Set<AnyCancellable> = []
    func getData() {
        let publisher: AnyPublisher<ToDo, APIError> = NetworkManager.shared.getData()
        publisher
            .receive(on: DispatchQueue.main)
            .sink { [weak self] apiError in
                guard let self else { return }
                guard let message = apiError.error?.errorDescription else {
                    return
                }
                showAlert = true
                alertMessage = message
            } receiveValue: { [weak self] toDo in
                guard let self else { return }
                self.todo = toDo
            }
            .store(in: &cancelSet)

    }
}

#Preview {
    ContentView()
}

enum APIError: Error {
    case invalidURL
    case invalidData
    case invalidResponse
    case defaultError(String)
    
    var errorDescription: String {
        switch self {
        case .invalidURL:
            "Given URL is invalid"
        case .invalidData:
            "Data is Invalid"
        case .invalidResponse:
            "Response is invalid"
        case .defaultError(let string):
            "Something went wrong \(string)"
        }
    }
}


struct ToDo: Codable {
    let userId: Int
    let id: Int
    let title: String
    let completed: String
}
class NetworkManager {
    static let shared: NetworkManager = NetworkManager()
    func getData<T: Codable>() -> AnyPublisher<T, APIError> {
        return URLSession
            .shared
            .dataTaskPublisher(for: URL(string: "https://jsonplaceholder.typicode.com/todos/1")!)
            .delay(for: 3, scheduler: DispatchQueue.main)
            .tryMap { data, response in
                guard let response = response as? HTTPURLResponse, (200...299).contains(response.statusCode) else {
                    throw APIError.invalidResponse
                }
                let jsonDecoder = JSONDecoder()
                return try jsonDecoder.decode(T.self, from: data)
            }
            .mapError { error in
                if let error1 = error as? APIError {
                    return error1
                }
                if let _ = error as? DecodingError {
                    return APIError.invalidData
                }
                return APIError.defaultError(error.localizedDescription)
            }
            .eraseToAnyPublisher()
            }
}

extension Subscribers.Completion {
    var error: Failure? {
        return switch self {
        case .failure(let failure2):
            failure2
        default:
            nil
        }
    }
}
