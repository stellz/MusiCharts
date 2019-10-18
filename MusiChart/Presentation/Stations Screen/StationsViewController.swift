import UIKit
import MarqueeLabel
import RxSwift

final class StationsViewController: UIViewController, ViewModelBased {
    
    var viewModel: StationsViewModeling?

    @IBOutlet var tableView: UITableView!
    @IBOutlet var animatedBarsImageView: UIImageView!
    @IBOutlet var nowPlayingStationLabel: MarqueeLabel!

    private var searchController: UISearchController!

    private let disposeBag = DisposeBag()
    
    // MARK: - ViewModel Binding
    
    func bindViewModel() {
        
        try? viewModel?.reachability?.startNotifier()
        
        viewModel?.loadStations(onStationDataLoaded: { [unowned self] in
            DispatchQueue.main.async(execute: {
                self.tableView.reloadData()
                self.view.setNeedsDisplay()
            })
        })
        
        viewModel?.isConnected
            .observeOn(MainScheduler.instance)
            .subscribe(onNext: { [unowned self] isConnected in
                if !isConnected {
                    self.showAlert(withTitle: "No Internet Detected", message: "This app requires an Internet connection")
                } else {
                    self.hideAlert()
                }
            }).disposed(by: disposeBag)
        
        bindNotifications()
    }
    
    private func bindNotifications() {
        
        NotificationCenter.default.rx.notification(Notification.Name(rawValue: StationNotifications.stationDidPlayPause))
            .map({ _ -> Void? in return nil })
            .asDriver(onErrorJustReturn: nil)
            .drive(onNext: { [weak self] _ in
                self?.pausePlayBarButtonPressed()
            }).disposed(by: disposeBag)
        
        NotificationCenter.default.rx.notification(Notification.Name(rawValue: StationNotifications.stationDidChange))
            .map({ return $0.object as? Bool })
            .asDriver(onErrorJustReturn: nil)
            .drive(onNext: { [weak self] reconnected in
                self?.updateLabels(statusMessage: "Loading...")
                self?.createRightBarButtons()
                guard let reconnected = reconnected else { return }
                if !reconnected {
                    self?.performSegue(withIdentifier: "NowPlaying", sender: self)
                }
            }).disposed(by: disposeBag)
        
        NotificationCenter.default.rx.notification(UIApplication.didBecomeActiveNotification)
            .map({ _ -> Void? in return nil })
            .asDriver(onErrorJustReturn: nil)
            .drive(onNext: { [weak self] _ in
                self?.updateLabels()
            }).disposed(by: disposeBag)
        
        NotificationCenter.default.rx.notification(NSNotification.Name.AVPlayerItemDidPlayToEndTime)
            .map({ _ -> Void? in return nil })
            .asDriver(onErrorJustReturn: nil)
            .drive(onNext: { _ in
                if kDebugLog { print("PlayerItemDidReachEnd. Detect end of mp3 when file is playing instead of a stream") }
            }).disposed(by: disposeBag)
        
        NotificationCenter.default.rx.notification(Notification.Name(rawValue: TimerNotifications.sleepTimeElapsed))
            .map({ return $0 })
            .asDriver(onErrorJustReturn: nil)
            .drive(onNext: { [weak self] _ in
                guard let currentTrack = self?.viewModel?.currentTrack else { return }
                if currentTrack.isPlaying {
                    self?.pausePlayBarButtonPressed()
                }
            }).disposed(by: disposeBag)
        
        NotificationCenter.default.rx.notification(Notification.Name(rawValue: AudioNotifications.audioFailedToPlay))
            .map({ return $0 })
            .asDriver(onErrorJustReturn: nil)
            .drive(onNext: { [weak self] _ in
                self?.showAlert(withTitle: "Station might be offline", message: "Try again later")
            }).disposed(by: disposeBag)
        
        NotificationCenter.default.rx.notification(Notification.Name(rawValue: SongNotification.currentSongChanged))
            .map({ return $0 })
            .asDriver(onErrorJustReturn: nil)
            .drive(onNext: { [weak self] _ in
                self?.nowPlayingStationLabel.text = self?.viewModel?.nowPlayingTitle
            }).disposed(by: disposeBag)
    }

    // MARK: - ViewDidLoad
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Set custom navigation bar color
        navigationController?.navigationBar.backgroundColor = viewModel?.themeManager.navigationBarColor

        configureTableView()
        createAnimatedBars()
        createLeftBarButtons()
        setupSearchController()
    }
    
    // MARK: - ViewWillAppear
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        title = "Player"
    }

    // MARK: - Setup UI
    
    private func configureTableView() {
        
        let cellNib = UINib(nibName: "NothingFoundCell", bundle: nil)
        tableView.register(cellNib, forCellReuseIdentifier: "NothingFound")
        tableView.backgroundColor = UIColor.clear
        tableView.backgroundView = nil
        tableView.separatorStyle = .none
    }

    private func createAnimatedBars() {
        
        animatedBarsImageView.animationImages = AnimationFrames.createFrames()
        animatedBarsImageView.animationDuration = 0.7
    }

    private func createRightBarButtons() {
        
        let nowPlayingButton = UIBarButtonItem(title: "", style: .plain, target: self, action: #selector(nowPlayingBarButtonPressed))
        nowPlayingButton.image = UIImage(named: "btn-nowPlaying")
        
        let pausePlayButton = UIBarButtonItem(title: "", style: .plain, target: self, action: #selector(pausePlayBarButtonPressed))
        pausePlayButton.image = UIImage(named: "pauseButton")
        
        navigationItem.rightBarButtonItems = [nowPlayingButton, pausePlayButton]
    }

    private func createLeftBarButtons() {
        
        let editButton = UIBarButtonItem(title: "Edit", style: .plain, target: self, action: #selector(toggleEditing))
        let addButton = UIBarButtonItem(title: "Add", style: .plain, target: self, action: #selector(addStation))
        
        navigationItem.leftBarButtonItems = [addButton, editButton]
    }

    private func setupSearchController() {
        
        searchController = UISearchController(searchResultsController: nil)

        if searchable {
            searchController.searchResultsUpdater = self
            searchController.dimsBackgroundDuringPresentation = false
            searchController.hidesNavigationBarDuringPresentation = false
            searchController.searchBar.sizeToFit()
            definesPresentationContext = true

            // Add UISearchController to the tableView
            tableView.tableHeaderView = searchController?.searchBar
            tableView.tableHeaderView?.backgroundColor = .clear

            // Style the UISearchController
            searchController.searchBar.setBackgroundImage(UIImage(), for: .any, barMetrics: .default)
            searchController.searchBar.scopeBarBackgroundImage = UIImage()

            // Hide the UISearchController
            tableView.setContentOffset(CGPoint(x: 0.0, y: searchController.searchBar.frame.size.height), animated: false)
        }
    }

    private func updateLabels(statusMessage: String = "") {
        
        if !statusMessage.isEmpty {
            nowPlayingStationLabel.text = statusMessage + (nowPlayingStationLabel.text ?? "")
            animatedBarsImageView.stopAnimating()
            return
        }
        
        guard let title = viewModel?.nowPlayingTitle else {
            animatedBarsImageView.stopAnimating()
            nowPlayingStationLabel.text = "Choose a station to begin."
            return
        }
        
        nowPlayingStationLabel.text = title
        animatedBarsImageView.startAnimating()
    }

    // MARK: - Radio stations list editing

    @objc private func addStation() {

        let alertController = UIAlertController(title: "Add Station", message: "Enter url for stream", preferredStyle: .alert)

        let cancelAction = UIAlertAction(title: "Cancel", style: .cancel) { _ in }
        let addAction = UIAlertAction(title: "Add Station", style: .default) { [weak self] _ in
            let stationName = alertController.textFields?.first?.text
            let stationURL = alertController.textFields?.last?.text
            self?.viewModel?.addStation(with: (name: stationName, url: stationURL))
            self?.tableView.reloadData()
        }

        alertController.addTextField { (textField) in
            textField.placeholder = "Station Name"
            textField.autocapitalizationType = .words
        }
        alertController.addTextField { (textField) in
            textField.placeholder = "Station URL"
        }

        alertController.addAction(addAction)
        alertController.addAction(cancelAction)

        present(alertController, animated: true, completion: nil)
    }

    @objc private func toggleEditing() {
        
        tableView.setEditing(!tableView.isEditing, animated: true)
        navigationItem.leftBarButtonItems?.last?.title = tableView.isEditing ? "Done" : "Edit"
    }

    // MARK: - Actions

    @objc func pausePlayBarButtonPressed() {
        
        guard let isPlaying = viewModel?.currentTrack?.isPlaying else { return }
        let button = navigationItem.rightBarButtonItems?.last
        
        if isPlaying {
            viewModel?.pauseStation()
            button?.image = UIImage(named: "playButton")
            updateLabels(statusMessage: "Station Paused. ")
        } else {
            viewModel?.playStation()
            button?.image = UIImage(named: "pauseButton")
            updateLabels()
        }

        guard let pausePlayButton = button else { return }
        navigationItem.rightBarButtonItems?.removeLast()
        navigationItem.rightBarButtonItems?.append(pausePlayButton)
    }

    @objc func nowPlayingBarButtonPressed() {
        
        guard let currentTrack = viewModel?.currentTrack else { return }
        if currentTrack.isPlaying {
            performSegue(withIdentifier: "NowPlaying", sender: self)
        }
    }

    @IBAction func nowPlayingLabelPressed(_ sender: UITapGestureRecognizer) {
        
        guard let currentTrack = viewModel?.currentTrack else { return }
        if currentTrack.isPlaying {
            performSegue(withIdentifier: "NowPlaying", sender: self)
        }
    }

    // MARK: - Segue

    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        
        if segue.identifier == "NowPlaying" {
            title = ""
            guard let viewModel = viewModel, let currentStation = viewModel.currentStation, let currentTrack = viewModel.currentTrack else { return }
            let nowPlayingViewModel = NowPlayingViewModel(rxLastFM: RxLastFMServiceProvider(),
                                                          settingsManager: viewModel.settingsManager,
                                                          currentStation: currentStation,
                                                          currentTrack: currentTrack)
            nowPlayingViewModel.delegate = self
            let nowPlayingVC = segue.destination as? NowPlayingViewController
            nowPlayingVC?.bindViewModel(to: nowPlayingViewModel)
        }
    }
    
    // MARK: - deinit
    
    deinit {
        debugPrint("deinit \(type(of: self))")
        viewModel?.reachability?.stopNotifier()
    }
}

// MARK: - NowPlayingViewModel Delegate

extension StationsViewController: NowPlayingViewModelDelegate {
    
    func nowPlayingViewModel(_ nowPlayingViewModel: NowPlayingViewModeling, didUpdateArtwork track: Track?) {
        guard let track = track else { return }
        viewModel?.updateCurrentTrack(track)
    }
}

// MARK: - TableViewDataSource

extension StationsViewController: UITableViewDataSource {

    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 88.0
    }

    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {

        guard let viewModel = viewModel else { return 0 }
        
        if searchController.isActive {
            return viewModel.searchedStations.count
        } else {
            return viewModel.stations.count
        }
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {

        guard let viewModel = viewModel, !viewModel.stations.isEmpty else {
            let cell = tableView.dequeueReusableCell(withIdentifier: "NothingFound", for: indexPath)
            cell.backgroundColor = UIColor.clear
            cell.selectionStyle = UITableViewCell.SelectionStyle.none
            return cell
        }
       
        guard let cell = tableView.dequeueReusableCell(withIdentifier: "StationCell", for: indexPath) as? StationCell else { return UITableViewCell() }
        
        // Alternate the background color of the cells
        if indexPath.row % 2 == 0 {
            cell.backgroundColor = UIColor.clear
        } else {
            cell.backgroundColor = UIColor.black.withAlphaComponent(0.2)
        }
  
        let station = searchController.isActive ? viewModel.searchedStations[indexPath.row] : viewModel.stations[indexPath.row]
        let stationCellViewModel = StationCellViewModel(station: station)
        cell.viewModel = stationCellViewModel
        
        return cell
    }
    
    // Delete on swipe left
    func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        return true
    }
    
    func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == .delete {
            viewModel?.removeStation(at: indexPath.row)
            tableView.deleteRows(at: [indexPath], with: .fade)
        }
    }
}

// MARK: - TableViewDelegate

extension StationsViewController: UITableViewDelegate {

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        
        tableView.deselectRow(at: indexPath, animated: true)
        viewModel?.playStation(at: indexPath.row, fromSearch: searchController.isActive)
    }
}

// MARK: - UISearchControllerDelegate

extension StationsViewController: UISearchResultsUpdating {

    func updateSearchResults(for searchController: UISearchController) {

        guard let searchText = searchController.searchBar.text else { return }
        viewModel?.updateSearchResults(searchText: searchText)
        tableView.reloadData()
    }
}
