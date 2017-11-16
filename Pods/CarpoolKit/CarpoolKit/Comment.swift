import FirebaseCommunity
import PromiseKit

public struct Comment: Codable {
    public let time: Date
    public let body: String
    public let user: User

    static func make(id: String) -> Promise<Comment> {
        return firstly {
            Database.fetch(path: "comments", id)
        }.then { snapshot in
            return Comment.make(snapshot: snapshot)
        }
    }

    static func make(snapshot: DataSnapshot) -> Promise<Comment> {
        do {
            guard let ctime = snapshot.childSnapshot(forPath: "ctime").value as? TimeInterval else { throw API.Error.noChildNode }
            let body = try snapshot.childSnapshot(forPath: "body").string()
            let owner = API.fetchUser(id: try snapshot.childSnapshot(forPath: "owner").string())

            return firstly {
                owner
            }.then { user in
                Comment(time: Date(timeIntervalSince1970: ctime), body: body, user: user)
            }
        } catch {
            return Promise(error: error)
        }
    }
}


public extension API {
    static func add(comment: String, to: Trip) {
        let uid = Auth.auth().currentUser!.uid   //FIXME bang

        let ref1 = Database.database().reference().child("comments").childByAutoId()
        ref1.setValue([
            "body": comment,
            "owner": uid,
            "ctime": Date().timeIntervalSince1970
        ])

        let ref2 = Database.database().reference().child("trips").child(to.key).child("comments")
        ref2.updateChildValues([
            ref1.key: true
        ])
    }
}
