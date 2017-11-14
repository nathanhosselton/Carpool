import UIKit
import CarpoolKit

private enum AddFriendError: UserError {
    case alreadyInFriends

    var description: String {
        switch self {
        case .alreadyInFriends:
            return "This person is already in your friends list."
        }
    }
}

final class AddFriendViewController: UITableViewController {
    private let search = UISearchBar()

    private var results: [CarpoolKit.User] = []
    private var friends: [CarpoolKit.User] = []

    override func viewDidLoad() {
        super.viewDidLoad()

        self.title = "Add a friend"

        tableView.register(Cell.self, forCellReuseIdentifier: Cell.reuseId)
        tableView.tableHeaderView = search

        search.placeholder = "Search for someone by name"
        search.delegate = self
        search.enablesReturnKeyAutomatically = true
        search.sizeToFit()

        API.observeFriends(sender: self) { (result) in
            switch result {
            case .success(let friends):
                self.friends = friends
                self.tableView.reloadSections(IndexSet(integer: 1), with: .automatic)
            case .failure(let error):
                self.show(error)
            }
        }
    }

    override func numberOfSections(in tableView: UITableView) -> Int {
        return 2
    }

    override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        return [results.count > 0 ? "Search Results" : nil, "Current Friends"][section]
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return users(forSection: section).count
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: Cell.reuseId, for: indexPath)
        cell.textLabel?.text = user(for: indexPath).name
        return cell
    }

    override func tableView(_ tableView: UITableView, editingStyleForRowAt indexPath: IndexPath) -> UITableViewCellEditingStyle {
        guard indexPath.section == 1 else { return .none }
        return .delete
    }

    override func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCellEditingStyle, forRowAt indexPath: IndexPath) {
        remove(user: friends[indexPath.row])
    }

    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        add(user: results[indexPath.row])
    }

    private func users(forSection section: Int) -> [CarpoolKit.User] {
        return [results, friends][section]
    }

    private func user(for indexPath: IndexPath) -> CarpoolKit.User {
        return users(forSection: indexPath.section)[indexPath.row]
    }

    private func remove(user: CarpoolKit.User) {
        API.remove(friend: user)
    }

    private func add(user: CarpoolKit.User) {
        guard !friends.contains(user) else { return show(AddFriendError.alreadyInFriends) }
        API.add(friend: user)
    }

}

extension AddFriendViewController: UISearchBarDelegate {
    func searchBarSearchButtonClicked(_: UISearchBar) {
        guard let name = search.text?.chuzzled else { return }

        API.search(forUsersWithName: name).then { users -> Void in
            self.results = users
            self.tableView.reloadSections(IndexSet(integer: 0), with: .automatic)
        }.catch {
            self.show($0)
        }
    }

    func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
        guard searchText.chuzzled == nil, !results.isEmpty else { return }
        results = []
        tableView.reloadSections(IndexSet(integer: 0), with: .automatic)
    }
}

private final class Cell: UITableViewCell {
    static var reuseId: String {
        return String(describing: Cell.self)
    }

    override init(style: UITableViewCellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        textLabel?.adjustsFontSizeToFitWidth = true
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("Cell.init(coder:) has not been implemented")
    }
}
