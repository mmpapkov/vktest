//
//  ContentView.swift
//  vktest
//
//  Created by Matvey on 02.12.2024.
//

import SwiftUI
import Combine

struct Repository: Codable, Identifiable, Equatable {
    let id: Int
    let name: String
    let description: String?
    let owner: Owner

    static func == (lhs: Repository, rhs: Repository) -> Bool {
        return lhs.id == rhs.id
    }
}

struct Owner: Codable {
    let avatar_url: String
}

class APIService {
    static let shared = APIService()

    func fetchRepositories(page: Int, completion: @escaping ([Repository]?) -> Void) {
        let url = URL(string: "https://api.github.com/search/repositories?q=programming&sort=stars&order=desc&page=\(page)")!
        let task = URLSession.shared.dataTask(with: url) { data, _, error in
            guard let data = data, error == nil else {
                completion(nil)
                return
            }
            let response = try? JSONDecoder().decode(GitHubResponse.self, from: data)
            completion(response?.items)
        }
        task.resume()
    }
}

struct GitHubResponse: Codable {
    let items: [Repository]
}

class RepositoryViewModel: ObservableObject {
    @Published var repositories: [Repository] = []
    @Published var localRepositories: [Repository] = []
    @Published var isLoading: Bool = false
    private var currentPage = 1
    private let storageKey = "LocalRepositories"
    init() {
        loadLocalRepositories()
    }
    func loadMore() {
        guard !isLoading else { return }
        isLoading = true
        APIService.shared.fetchRepositories(page: currentPage) { [weak self] repos in
            DispatchQueue.main.async {
                if let repos = repos {
                    self?.repositories.append(contentsOf: repos)
                    self?.currentPage += 1
                }
                self?.isLoading = false
            }
        }
    }
    func addLocalRepository(_ repository: Repository) {
        if !localRepositories.contains(repository) {
            localRepositories.append(repository)
            saveLocalRepositories()
        }
    }
    func removeLocalRepository(_ repository: Repository) {
        if let index = localRepositories.firstIndex(of: repository) {
            localRepositories.remove(at: index)
            saveLocalRepositories()
        }
    }
    private func saveLocalRepositories() {
        if let data = try? JSONEncoder().encode(localRepositories) {
            UserDefaults.standard.set(data, forKey: storageKey)
        }
    }
    private func loadLocalRepositories() {
        if let data = UserDefaults.standard.data(forKey: storageKey),
           let repositories = try? JSONDecoder().decode([Repository].self, from: data) {
            localRepositories = repositories
        }
    }
}

class FPSCounter: ObservableObject {
    @Published var fps: Int = 0
    private var displayLink: CADisplayLink?
    private var lastTimestamp: CFTimeInterval = 0
    private var frameCount = 0

    init() {
        start()
    }

    func start() {
        displayLink = CADisplayLink(target: self, selector: #selector(updateFPS))
        displayLink?.add(to: .main, forMode: .common)
    }

    func stop() {
        displayLink?.invalidate()
        displayLink = nil
    }

    @objc private func updateFPS(link: CADisplayLink) {
        if lastTimestamp == 0 {
            lastTimestamp = link.timestamp
            return
        }

        frameCount += 1
        let delta = link.timestamp - lastTimestamp

        if delta >= 1 {
            fps = frameCount
            frameCount = 0
            lastTimestamp = link.timestamp
        }
    }
}

struct ContentView: View {
    @StateObject private var viewModel = RepositoryViewModel()
    @StateObject private var fpsCounter = FPSCounter()

    var body: some View {
        NavigationView {
            ZStack(alignment: .topTrailing) {
                List {
                    Section(header: Text("Удаленные репозитории")) {
                        ForEach(viewModel.repositories) { repo in
                            RepositoryRow(repository: repo) {
                                viewModel.addLocalRepository(repo)
                            }
                        }
                    }
                    Section(header: Text("Локальные репозитории")) {
                        ForEach(viewModel.localRepositories) { repo in
                            RepositoryRow(repository: repo) {
                                viewModel.removeLocalRepository(repo)
                            }
                        }
                        .onDelete { indexSet in
                            indexSet.forEach { index in
                                let repo = viewModel.localRepositories[index]
                                viewModel.removeLocalRepository(repo)
                            }
                        }
                    }
                }
                .navigationBarTitle("Репозитории", displayMode: .inline)
                .onAppear {
                    viewModel.loadMore()
                }
                if viewModel.isLoading {
                    ProgressView()
                        .scaleEffect(1.5)
                        .padding()
                        .frame(maxWidth: .infinity, alignment: .center)
                }
                Text("\(fpsCounter.fps) FPS")
                    .font(.caption)
                    .padding(8)
                    .background(Color.black.opacity(0.7))
                    .foregroundColor(.white)
                    .clipShape(Capsule())
                    .padding()
            }
        }
        .navigationViewStyle(StackNavigationViewStyle())
        .edgesIgnoringSafeArea(.all)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

struct RepositoryRow: View {
    let repository: Repository
    let onAction: () -> Void

    var body: some View {
        HStack(alignment: .center, spacing: 16) {
            AsyncImage(url: URL(string: repository.owner.avatar_url)) { image in
                image
                    .resizable()
                    .scaledToFill()
                    .frame(width: 50, height: 50)
                    .clipShape(Circle())
            } placeholder: {
                ProgressView()
                    .frame(width: 50, height: 50)
            }
            VStack(alignment: .leading, spacing: 4) {
                Text(repository.name)
                    .font(.headline)
                    .lineLimit(1)
                    .frame(maxWidth: .infinity, alignment: .leading)
                Text(repository.description ?? "No description")
                    .font(.subheadline)
                    .foregroundColor(.gray)
                    .lineLimit(2)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
            Spacer()
            Button("Добавить") {
                onAction()
            }
            .buttonStyle(.bordered)
        }
        .padding(.vertical, 8)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

#Preview {
    ContentView()
}
