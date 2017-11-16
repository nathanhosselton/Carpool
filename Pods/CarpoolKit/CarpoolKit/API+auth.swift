import FirebaseCommunity
import CoreLocation
import PromiseKit

public extension API {
    static func signUp(email: String, password: String, fullName: String) -> Promise<User> {
        func set(userFullName: String) {
            guard let user = Auth.auth().currentUser else { return }

            let rq = user.createProfileChangeRequest()
            rq.displayName = userFullName
            rq.commitChanges(completion: nil)

            Database.database().reference().child("users").child(user.uid).child("name").setValue(userFullName)
        }

        if let user = Auth.auth().currentUser {
            set(userFullName: fullName)  //FIXME strictly shouldn't do this unless `link` succeeds
            Database.database().reference().child("users").child(user.uid).updateChildValues([
                "name": fullName
                ])
            return link(user: user, email: email, password: password).then { user in
                // we need to set the username for both the anonymous user and the new user
                set(userFullName: fullName)
                return Promise(value: user)
            }
        } else {
            return firstly {
                PromiseKit.wrap{ Auth.auth().createUser(withEmail: email, password: password, completion: $0) }
            }.then { user in
                auth().then {
                    Database.database().reference().child("users").child(user.uid).updateChildValues([
                        "name": fullName
                        ])
                }
            }.then {
                fetchCurrentUser()
            }
        }
    }

    static func signUp(email: String, password: String, fullName: String, completion: @escaping (Result<User>) -> Void) {
        signUp(email: email, password: password, fullName: fullName).then {
            completion(.success($0))
        }.catch {
            completion(.failure($0))
        }
    }

    static func signIn(email: String, password: String, completion: @escaping (Result<User>) -> Void) {
        signIn(email: email, password: password).then {
            completion(.success($0))
        }.catch {
            completion(.failure($0))
        }
    }

    /// This is the `Promise` returning variant of this function.
    /// Use the original `signIn(email:password:completion:)` unless you intend to use Promises.
    static func signIn(email: String, password: String) -> Promise<User> {
        //FIXME cannot link anonymous account this way, Firebase errors saying the account is already linked
        // (referring to the email/pass account)
        return firstly {
            PromiseKit.wrap{ Auth.auth().signIn(withEmail: email, password: password, completion: $0) }
        }.then { _ in
            auth()
        }.then {
            fetchCurrentUser()
        }
    }
}


//MARK: HERE BE DRAGONS

private extension API {
    static func link(user: FirebaseCommunity.User, email: String, password: String) -> Promise<User> {
        let creds = EmailAuthProvider.credential(withEmail: email, password: password)

        return Promise { (fulfill, reject) in
            user.link(with: creds, completion: { user, error in
                if user != nil {
                    fetchCurrentUser().then{ fulfill($0) }.catch{ reject($0) }
                } else if let error = error {
                    reject(Error.signInFailed(underlyingError: error))
                } else {
                    reject(Error.signInFailed(underlyingError: PMKError.invalidCallingConvention))
                }
            })
        }
    }

    static func link(user: FirebaseCommunity.User, email: String, password: String, completion: @escaping (Result<User>) -> Void) {
        link(user: user, email: email, password: password).then {
            completion(.success($0))
        }.catch {
            completion(.failure($0))
        }
    }
}

extension API {
    static func auth() -> Promise<Void> {
        func foo() -> Promise<FirebaseCommunity.User> {
            if let foo = Auth.auth().currentUser { return Promise(value: foo) }
            return PromiseKit.wrap(Auth.auth().signInAnonymously)
        }

        return firstly {
            foo()
        }.then { fbuser in
            Database.fetch(path: "users", fbuser.uid)
        }.then { snapshot -> Void in
            let ctime = snapshot.childSnapshot(forPath: "ctime")
            if ctime.value == nil {
                ctime.ref.setValue(Date().timeIntervalSince1970)
            }
        }
    }
}
