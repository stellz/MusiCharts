import UIKit
import Spring
import MediaPlayer
import RxSwift
import RxCocoa

final class NowPlayingViewController: UIViewController, ViewModelBased {
    
    var viewModel: NowPlayingViewModeling?

    // Currently playing audio track UI elements
    @IBOutlet var albumImageView: SpringImageView!
    @IBOutlet var artistLabel: UILabel!
    @IBOutlet var songLabel: SpringLabel!
    @IBOutlet var stationDescLabel: UILabel!

    // The volume slider UI
    @IBOutlet var volumeParentView: UIView!
    var mpVolumeSlider = UISlider()
    @IBOutlet var slider: UISlider!

    // Action buttons
    @IBOutlet var loveButton: UIButton!
    @IBOutlet var playButton: UIButton!

    // The animated bars in the navigation bar
    var animatedBarsImageView: UIImageView!
    
    let disposeBag = DisposeBag()
    
    // MARK: - ViewModel Binding
    
    func bindViewModel() {
        
        title = viewModel?.currentStation.stationName
        albumImageView.image = viewModel?.currentTrack.artworkImage
        
        bindNotifications()
    }
    
    private func bindNotifications() {
        
        NotificationCenter.default.rx.notification(UIApplication.didBecomeActiveNotification)
            .map({ _ -> Void? in return nil })
            .asDriver(onErrorJustReturn: nil)
            .drive(onNext: { [weak self] _ in
                self?.updateLabels()
                self?.updateAlbumArtwork()
            }).disposed(by: disposeBag)
        
        NotificationCenter.default.rx.notification(Notification.Name(rawValue: SystemVolumeNotification.didChangeNotification))
            .map({ return $0 })
            .asDriver(onErrorJustReturn: nil)
            .drive(onNext: { [weak self] notification in
                // Update the slider value from the device volume buttons
                guard let notification = notification, let userInfo = notification.userInfo else { return }
                guard let volume = userInfo[SystemVolumeNotification.parameter] as? Float else { return }
                self?.slider.value = volume
            }).disposed(by: disposeBag)
        
        NotificationCenter.default.rx.notification(Notification.Name(rawValue: SongNotification.currentSongChanged))
            .map({ return $0 })
            .asDriver(onErrorJustReturn: nil)
            .drive(onNext: { [weak self] notification in
    
                guard let notification = notification, let track = notification.object as? Track else { return }
                self?.resetUI(with: track)

                guard let self = self, let viewModel = self.viewModel else { return }
                viewModel.getAlbumArtURL.execute(track)
                    .observeOn(MainScheduler.instance)
                    .subscribe(onNext: { [weak self] artUrl in
                        self?.updateAlbumArtwork(artUrl)
                    }).disposed(by: self.disposeBag)
                
            }).disposed(by: disposeBag)
        
        NotificationCenter.default.rx.notification(Notification.Name(rawValue: TimerNotifications.sleepTimeElapsed))
            .map({ _ -> Void? in return nil })
            .asDriver(onErrorJustReturn: nil)
            .drive(onNext: { [weak self] _ in
                guard let self = self else { return }
                self.playButton.isSelected = !self.playButton.isSelected
                if self.playButton.isSelected {
                    self.animatedBarsImageView.stopAnimating()
                } else {
                    self.animatedBarsImageView.startAnimating()
                }
            }).disposed(by: disposeBag)
    }

    // MARK: - ViewDidLoad

    override func viewDidLoad() {
        super.viewDidLoad()

        createAnimatedBars()
        updateLabels()
        startBarsAnimation()
        setupVolumeSlider()
    }
    
    // MARK: - viewWillAppear
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        // Fixes the disappearing title of the tabbar item when navigating between player and now playing screen
        navigationController?.tabBarItem.title = "Player"
    }

    // MARK: - UI
    
    private func resetUI(with track: Track) {
        
        // Reset the buttons when song changes
        loveButton.isSelected = false
        loveButton.isHidden = false
        playButton.isSelected = false
        playButton.isHidden = false
        
        // Update Labels
        artistLabel.text = track.artist
        songLabel.text = track.title
        
        // songLabel animation
        songLabel.animation = "zoomIn"
        songLabel.duration = 1.5
        songLabel.damping = 1
        songLabel.animate()
    }

    private func setupVolumeSlider() {
    
        // The volume slider only works in devices, not the simulator.
        volumeParentView.backgroundColor = .clear
        let volumeView = MPVolumeView(frame: volumeParentView.bounds)
        for view in volumeView.subviews {
            if view.description.contains("MPVolumeSlider") {
                if let view = view as? UISlider {
                    mpVolumeSlider = view
                }
            }
        }

        let thumbImageNormal = UIImage(named: "slider-ball")
        slider?.setThumbImage(thumbImageNormal, for: .normal)
        slider?.value = AVAudioSession.sharedInstance().outputVolume
    }
    
    private func startBarsAnimation() {
        guard let viewModel = viewModel else { return }
        if viewModel.currentTrack.isPlaying {
            animatedBarsImageView.startAnimating()
        }
    }

    private func updateLabels(statusMessage: String = "") {

        guard let viewModel = viewModel else { return }
        songLabel.text = viewModel.currentTrack.title
        artistLabel.text = viewModel.currentTrack.artist

        stationDescLabel.text = viewModel.currentStation.stationDesc
        stationDescLabel.isHidden = viewModel.currentTrack.artworkLoaded
        
        // Hide the buttons if there is no song title showing
        loveButton.isHidden = songLabel.text == ""
        playButton.isHidden = songLabel.text == ""
    }

    private func createAnimatedBars() {

        // Setup ImageView
        animatedBarsImageView = UIImageView(image: UIImage(named: "NowPlayingBars-3"))
        animatedBarsImageView.autoresizingMask = []
        animatedBarsImageView.contentMode = UIView.ContentMode.center

        // Create Animation
        animatedBarsImageView.animationImages = AnimationFrames.createFrames()
        animatedBarsImageView.animationDuration = 0.7

        // Create Top BarButton
        let barButton = UIButton(type: UIButton.ButtonType.custom)
        barButton.frame = CGRect(x: 0, y: 0, width: 40, height: 40)
        barButton.addSubview(animatedBarsImageView)
        animatedBarsImageView.center = barButton.center

        // Put the button in the navigation bar
        let barItem = UIBarButtonItem(customView: barButton)
        navigationItem.rightBarButtonItem = barItem

    }

    // MARK: - Album Art

    private func updateAlbumArtwork(_ urlString: String? = nil) {
        
        guard let viewModel = viewModel, let urlString = urlString, !viewModel.currentTrack.artworkURL.isEmpty else { return }
        
        let isValidURL = urlString.contains("http")
        if isValidURL {
            guard let url = URL(string: urlString) else { return }
            
            // Attempt to download album art from an API. We don't need to cache this image
            viewModel.loadImageWithURL(url: url) { [weak self] (image) in
                
                DispatchQueue.main.async {
                    self?.albumImageView.image = image
                    
                    // Animate artwork
                    self?.albumImageView.animation = "wobble"
                    self?.albumImageView.duration = 2
                    self?.albumImageView.animate()
                    self?.stationDescLabel.isHidden = true
                }
            }
        }

        // Force app to update display
        DispatchQueue.main.async {
            self.view.setNeedsDisplay()
        }
    }

    // MARK: - Actions

    @IBAction func volumeChanged(_ sender: UISlider) {
        // Note: This slider implementation uses a MPVolumeView
        // The volume slider only works in devices, not the simulator.
        mpVolumeSlider.value = sender.value
    }

    @IBAction func playPauseButtonPressed(_ sender: UIButton) {
        sender.isSelected = !sender.isSelected
        if sender.isSelected {
            animatedBarsImageView.stopAnimating()
        } else {
            animatedBarsImageView.startAnimating()
        }
        NotificationCenter.default.post(name: NSNotification.Name(StationNotifications.stationDidPlayPause), object: sender.isSelected)
    }

    @IBAction func loveButtonPressed(_ sender: UIButton) {
        sender.isSelected = !sender.isSelected
        guard let song = songLabel.text else { return }
        guard let artist = artistLabel.text else { return }
        viewModel?.loveTrack(sender.isSelected, song: song, artist: artist)
    }
    
    // MARK: - deinit
    
    deinit {
        debugPrint("deinit \(type(of: self))")
    }
}
