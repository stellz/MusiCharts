import UIKit
import RxSwift

final class SettingsViewController: UIViewController, ViewModelBased {
    
    var viewModel: SettingsViewModeling?

    @IBOutlet var profileImageView: UIImageView!
    @IBOutlet var usernameTextField: UITextField!
    @IBOutlet var passwordTextField: UITextField!
    @IBOutlet var loginButton: UIButton!

    @IBOutlet var sleepTimerControl: UISegmentedControl!

    @IBOutlet var radioSwitch: UISwitch!
    @IBOutlet var audioSwitch: UISwitch!

    private let disposeBag = DisposeBag()

    // MARK: - ViewDidLoad

    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
    // MARK: - ViewWillAppear
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        try? viewModel?.reachability?.startNotifier()
    }
    
    // MARK: - ViewWillDisappear
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        viewModel?.reachability?.stopNotifier()
    }

    // MARK: - ViewDidAppear
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        guard let viewModel = viewModel else { return }
        if viewModel.resetSleepTimer() {
            sleepTimerControl.selectedSegmentIndex = 0
        }
    }
    
    // MARK: - Bind ViewModel

    func bindViewModel() {
        
        guard let viewModel = viewModel else { return }
        
        viewModel.isConnected
            .asDriver(onErrorJustReturn: false)
            .drive(onNext: { [unowned self] isConnected in
                if !isConnected {
                    self.showAlert(withTitle: "No Internet Detected", message: "This app requires an Internet connection")
                } else {
                    self.hideAlert()
                }
            }).disposed(by: disposeBag)

        viewModel.radioScrobbling
            .bind(to: radioSwitch.rx.isOn)
            .disposed(by: disposeBag)

        viewModel.audioScrobbling
            .bind(to: audioSwitch.rx.isOn)
            .disposed(by: disposeBag)
        
        audioSwitch.rx.value
            .bind(to: radioSwitch.rx.isEnabled)
            .disposed(by: disposeBag)
        
        viewModel.username
            .asDriver(onErrorJustReturn: "")
            .drive(onNext: { [unowned self] name in
                if let name = name, !name.isEmpty {
                    self.usernameTextField.text = name
                    self.passwordTextField.text = name
                    self.usernameTextField.isEnabled = false
                    self.passwordTextField.isEnabled = false
                    self.loginButton.setTitle("Logout", for: .normal)
                } else {
                    self.usernameTextField.isEnabled = true
                    self.passwordTextField.isEnabled = true
                    self.passwordTextField.text = nil
                    self.loginButton.setTitle("Login", for: .normal)
                }
            }).disposed(by: disposeBag)
        
        viewModel.imgUrlPath
            .asDriver(onErrorJustReturn: nil)
            .drive(onNext: { [unowned self] imgUrlPath in
                guard let imgUrlPath = imgUrlPath, let url = URL(string: imgUrlPath) else {
                    self.profileImageView.image = UIImage(named: "Profile")
                    return
                }
                self.profileImageView.sd_setImage(with: url)
                self.profileImageView.layer.cornerRadius = self.profileImageView.frame.size.width / 2
                self.profileImageView.layer.masksToBounds = true
            }).disposed(by: disposeBag)
        
        sleepTimerControl.rx.selectedSegmentIndex
            .subscribe (onNext: { [weak self] index in
                guard let title = self?.sleepTimerControl.titleForSegment(at: index)
                    else { return }
                viewModel.updateSleepTimer(title)
            })
            .disposed(by: disposeBag)
        
        prepareLoginButton()
    }
    
    private func prepareLoginButton() {
        
        guard let viewModel = viewModel else { return }
        
        let isUsernameVaild = usernameTextField.rx.text.orEmpty
            .map { $0.count >= 1 }
            .distinctUntilChanged()
        
        let isPasswordValid = passwordTextField.rx.text.orEmpty
            .map { $0.count >= 1 }
            .distinctUntilChanged()
        
        let isLoginButtonEnabled = Observable.combineLatest(isUsernameVaild, isPasswordValid, viewModel.isConnected) { $0 && $1 && $2 }
        
        isLoginButtonEnabled
            .bind(to: loginButton.rx.isEnabled)
            .disposed(by: disposeBag)
        
        let inputObs = Observable.combineLatest(usernameTextField.rx.text.orEmpty,
                                                passwordTextField.rx.text.orEmpty,
                                                resultSelector: { (username, password) -> (username: String, password: String) in
                                                    return (username: username, password: password) })
        
        loginButton.rx.tap
            .withLatestFrom(inputObs)
            .subscribe(onNext: { [weak self] loginData in
                guard let self = self else { return }
                switch self.loginButton.currentTitle {
                case "Login":
                    //Hide the keyboard
                    self.view.endEditing(true)
                    self.viewModel?.loginAction
                        .execute(loginData)
                        .asDriver(onErrorJustReturn: nil)
                        .drive(onNext: { [unowned self] result in
                            guard let result = result else {
                                self.showAlert(withTitle: "Login unsuccessful", message: "Wrong username or password")
                                return
                            }
                            switch result {
                            case .error:
                                self.showAlert(withTitle: "Login unsuccessful", message: "Couldn't save credentials")
                            case .result:
                                break
                            }
                        })
                        .disposed(by: self.disposeBag)
                case "Logout":
                    self.viewModel?.logoutAction.execute(())
                default:
                    break
                }
            })
            .disposed(by: disposeBag)
        
        Observable.combineLatest(audioSwitch.rx.value.startWith(audioSwitch.isOn),
                                 radioSwitch.rx.value.startWith(radioSwitch.isOn),
                                 resultSelector: { (audioSwitchEnabled, radioSwitchEnabled) -> (Bool, Bool) in
                                    return (audioSwitchEnabled, radioSwitchEnabled)
        }).subscribe(onNext: { [weak self] inputs in
            let scrobblingSettings = Settings.Scrobbling(audioEnabled: inputs.0, radioEnabled: inputs.1)
            let settings = Settings(scrobbling: scrobblingSettings)
            self?.viewModel?.saveSettingsAction.execute(settings)
        }).disposed(by: disposeBag)
    }
    
    // MARK: - deinit
    
    deinit {
        debugPrint("deinit \(type(of: self))")
    }
}
