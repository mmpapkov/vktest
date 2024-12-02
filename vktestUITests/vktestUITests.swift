//
//  vktestUITests.swift
//  vktestUITests
//
//  Created by Matvey on 02.12.2024.
//

import XCTest
@testable import vktest

final class RepositoryViewModelTests: XCTestCase {
    var viewModel: RepositoryViewModel!

    override func setUp() {
        super.setUp()
        viewModel = RepositoryViewModel()
    }

    override func tearDown() {
        viewModel = nil
        super.tearDown()
    }

    func testAddLocalRepository() {
        let repository = Repository(
            id: 1,
            name: "Test",
            description: "Description",
            owner: Owner(avatar_url: "")
        )
        viewModel.addLocalRepository(repository)
        XCTAssertTrue(viewModel.localRepositories.contains(repository))
    }

    func testRemoveLocalRepository() {
        let repository = Repository(
            id: 1,
            name: "Test",
            description: "Description",
            owner: Owner(avatar_url: "")
        )
        viewModel.addLocalRepository(repository)
        viewModel.removeLocalRepository(repository)
        XCTAssertFalse(viewModel.localRepositories.contains(repository))
    }

    func testUpdateLocalRepository() {
        let repository = Repository(
            id: 1,
            name: "Test",
            description: "Description",
            owner: Owner(avatar_url: "")
        )
        viewModel.addLocalRepository(repository)
        XCTAssertEqual(viewModel.localRepositories.first?.name, "Updated")
    }
}
