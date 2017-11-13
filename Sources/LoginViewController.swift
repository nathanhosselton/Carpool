import UIKit
import CarpoolKit

private let margin = 8.f

private enum LoginError: UserError {
    case notAllFieldsFilled
    case passwordsDoNotMatch

    var description: String {
        switch self {
        case .notAllFieldsFilled:
            return "You must fill in all fields to proceed."
        case .passwordsDoNotMatch:
            return "Your passwords do not match."
        }
    }
}

final class LoginViewController: UIViewController {
    private let pathControl: UISegmentedControl
    private let email: UITextField
    private let password: UITextField
    private let confirm: UITextField
    private let fullName: UITextField
    private let proceed: UIButton
    private let stack: UIStackView

    required init(coder: NSCoder = .null) {
        pathControl = UISegmentedControl(.byhand, "Log in", "Sign up")
        email = UITextField(.byhand, placeholder: "Email")
        password = UITextField(.byhand, placeholder: "Password")
        confirm = UITextField(.byhand, placeholder: "Confirm password")
        fullName = UITextField(.byhand, placeholder: "Your full name")
        proceed = UIButton(.byhand, title: "Proceed", font: UIFont.systemFont(ofSize: UIFont.buttonFontSize))
        stack = UIStackView(arrangedSubviews: [pathControl, email, password, confirm, fullName, proceed])

        super.init(nibName: nil, bundle: nil)
    }

    private var keyboardIsShowing: Bool {
        return stack.subviews.first{ $0.isFirstResponder } != nil
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        self.title = "Authenticate"
        view.backgroundColor = .white

        //View config

        pathControl.addTarget(self, action: #selector(onPathChange), for: .valueChanged)

        email.textContentType = .emailAddress
        email.enablesReturnKeyAutomatically = true
        email.addTarget(self, action: #selector(onEmailReturn), for: .editingDidEndOnExit)

        password.isSecureTextEntry = true
        password.enablesReturnKeyAutomatically = true
        password.addTarget(self, action: #selector(onPasswordReturn), for: .editingDidEndOnExit)

        confirm.isHidden = true
        confirm.isSecureTextEntry = true
        confirm.enablesReturnKeyAutomatically = true
        confirm.addTarget(self, action: #selector(onConfirmReturn), for: .editingDidEndOnExit)

        fullName.isHidden = true
        fullName.textContentType = .name
        fullName.enablesReturnKeyAutomatically = true
        fullName.addTarget(self, action: #selector(onFullNameReturn), for: .editingDidEndOnExit)

        proceed.addTarget(self, action: #selector(go), for: .touchUpInside)

        stack.axis = .vertical
        stack.distribution = .fillEqually
        stack.spacing = margin * 2

        view.addSubview(stack)

        //Etc

        NotificationCenter.default.addObserver(forName: .UIKeyboardWillShow, object: nil, queue: .main) { (note) in
            guard let kb = (note.userInfo?[UIKeyboardFrameEndUserInfoKey] as? NSValue)?.cgRectValue else { return }
            self.stack.center.y = (self.view.height - kb.height) / 2
        }
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        stack.size = stack.systemLayoutSizeFitting(UILayoutFittingCompressedSize)
        stack.width = width - margin * 2

        if !keyboardIsShowing {
            stack.center = view.center
        }
    }

    @objc func onPathChange() {
        if confirm.isFirstResponder || fullName.isFirstResponder { self.resignFirstResponder() }
        confirm.isHidden = !confirm.isHidden
        fullName.isHidden = confirm.isHidden
        view.setNeedsLayout()
        view.layoutIfNeeded()
    }

    @objc func onEmailReturn() {
        password.becomeFirstResponder()
    }

    @objc func onPasswordReturn() {
        switch pathControl.selectedSegmentIndex {
        case 0: logIn()
        case 1: confirm.becomeFirstResponder()
        default: fatalError()
        }
    }

    @objc func onConfirmReturn() {
        fullName.becomeFirstResponder()
    }

    @objc func onFullNameReturn() {
        signUp()
    }

    @objc func go() {
        switch pathControl.selectedSegmentIndex {
        case 0: logIn()
        case 1: signUp()
        default: fatalError()
        }
    }

    private var authed: (CarpoolKit.Result<User>) -> Void {
        return { (result) in
            switch result {
            case .success(_):
                self.dismiss(animated: true)
            case .failure(let error):
                self.show(error)
                print(#file, #function, error)
            }
        }
    }

    private func logIn() {
        guard let email = email.text?.chuzzled, let password = password.text?.chuzzled else { return show(LoginError.notAllFieldsFilled) }
        API.signIn(email: email, password: password, completion: authed)
    }

    private func signUp() {
        guard let email = email.text?.chuzzled, let password = password.text?.chuzzled, let name = fullName.text?.chuzzled else { return show(LoginError.notAllFieldsFilled) }
        guard password == confirm.text else { return show(LoginError.passwordsDoNotMatch) }
        API.signUp(email: email, password: password, fullName: name, completion: authed)
    }

}
