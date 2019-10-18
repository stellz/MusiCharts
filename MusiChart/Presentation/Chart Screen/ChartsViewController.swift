import UIKit
import RxSwift

final class ChartsViewController: UIViewController, ViewModelBased {
    
    var viewModel: ChartsViewModeling?

    @IBOutlet var realNameLabel: UILabel!
    @IBOutlet var scrobblesCountLabel: UILabel!
    @IBOutlet var scrobblingDateLabel: UILabel!
    // Placeholders when there is no logged in user
    @IBOutlet var lastFMLabel: UILabel!
    @IBOutlet var demoTitle: UILabel!
    @IBOutlet var chartDemoView: UIImageView!
    @IBOutlet var demoLabel: UILabel!
    // Overall top artist image and label to show when there is no recent play statistic
    @IBOutlet var topArtistImage: UIImageView!
    @IBOutlet var topArtistLabel: UILabel!
    // Pie chart showing the top 5 artists for the last week
    @IBOutlet var pieChart: ARPieChart!
    // Tableview showing the top 5 artist for the last week with the number of plays
    @IBOutlet var artistTableView: UITableView!
    // Tableview constraint to edit when there are less than 5 artists
    @IBOutlet var tableViewHeightConstraint: NSLayoutConstraint!
    // We need these bg and scrollview outlets to adjust them when we export the content as infogram image
    @IBOutlet var background: UIImageView!
    @IBOutlet var scrollView: UIScrollView!
    // Button to share an infogram image to different services like Photos, Facebook, etc.
    @IBOutlet var shareButton: UIButton!

    // Array to hold all PieChartItems
    var pieChartItems = [PieChartItem]()
    // Color array with a predifined pie chart item colors
    var colorArray = [UIColor]()
    
    // Artist array to hold the parsed info from the server. We will use it to populate the artist tableview with info and to build the pie chart
    var artistCellViewModels = [ArtistCellViewModel]()
    
    private let viewDidAppearPS = PublishSubject<Void>()
    
    let disposeBag = DisposeBag()
    
    // MARK: - ViewDidLoad
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        resetTopOverallArtist()
        configurePieChart()
    }
    
    // MARK: - ViewWillAppear
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        try? viewModel?.reachability?.startNotifier()
    }
    
    // MARK: - ViewDidAppear
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        viewDidAppearPS.onNext(())
    }
    
    // MARK: - ViewWillDisappear
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        viewModel?.reachability?.stopNotifier()
    }
    
    // MARK: - ViewModel Binding
    
    func bindViewModel() {
        
        guard let viewModel = viewModel else { return }
        
        Observable.combineLatest(viewDidAppearPS.take(1), viewModel.isConnected.startWith(false), viewModel.usernameObs.startWith(nil),
                                 resultSelector: { _, isConnected, username in
                                    return (connected: isConnected, username: username)
        })
            .skip(1)
            .asDriver(onErrorJustReturn: (connected:false, username: nil))
            .drive(onNext: { [weak self] info in
                let isConnected = info.connected
                if !isConnected {
                    guard let username = info.username, !username.isEmpty else {
                        self?.demoView(show: true)
                        self?.showAlert(withTitle: "No Internet Detected", message: "This app requires an Internet connection")
                        return
                    }
                    self?.showAlert(withTitle: "No Internet Detected", message: "This app requires an Internet connection")
                } else {
                    self?.demoView(show: false)
                    self?.hideAlert()
                    guard let username = info.username, !username.isEmpty else {
                        self?.demoView(show: true)
                        return
                    }
                    
                    self?.refreshData(for: username)
                }
            }).disposed(by: disposeBag)
        
        viewModel.registeredSince
            .bind(to: scrobblingDateLabel.rx.text)
            .disposed(by: disposeBag)
        
        viewModel.realName
            .bind(to: realNameLabel.rx.text)
            .disposed(by: disposeBag)
        
        viewModel.playcount
            .bind(to: scrobblesCountLabel.rx.text)
            .disposed(by: disposeBag)
        
        NotificationCenter.default.rx.notification(Notification.Name(rawValue: LastFMNotifications.didScrobbleTrack))
            .map({ _ -> Void? in return nil })
            .asDriver(onErrorJustReturn: nil)
            .drive(onNext: { [weak self] _ in
                if kDebugLog { print("New track scrobbled. Update chart") }
                guard let username = viewModel.username else { return }
                self?.refreshData(for: username)
            }).disposed(by: disposeBag)
    }
    
    // MARK: - Update data
    
    func refreshData(for username: String) {
        viewModel?.updatePlaycountAction
            .execute(username)
            .asDriver(onErrorJustReturn: nil)
            .drive(scrobblesCountLabel.rx.text)
            .disposed(by: disposeBag)
        getOverallTopArtist(for: username)
        getWeeksTop5Artist(for: username)
    }
    
    // Get the overall top artist for the logged in user
    private func getOverallTopArtist(for name: String) {
        
        viewModel?.getOverallTopArtistAction.execute(name)
            .asDriver(onErrorJustReturn: nil)
            .drive(onNext: { [unowned self] artist in
                guard let artist = artist else {
                    self.resetTopOverallArtist()
                    return
                }
                
                let combinedString = artist.name.combine(with: self.topArtistLabel)
                self.topArtistLabel.attributedText = combinedString
                
                guard let imageURL = URL(string: artist.imageURL) else { return }
                self.topArtistImage.sd_setImage(with: imageURL, completed: nil)
            }).disposed(by: disposeBag)
        
    }
    
    // Get the top 5 artists for the last week
    private func getWeeksTop5Artist(for name: String) {
        
        let userData = (username: name, period: LastFM.Period.week, limit: 5)
        viewModel?.getTopArtistsAction.execute(userData)
            .asDriver(onErrorJustReturn: nil)
            .drive(onNext: { [weak self] updatedViewModels in
                guard let updatedViewModels = updatedViewModels else {
                    return
                }
                self?.updateChart(with: updatedViewModels)
                self?.showOverallTopArtist(updatedViewModels.isEmpty)
            }).disposed(by: disposeBag)
        
    }
    
    //Check if the user has recent plays, get the data and update the onscreen info
    private func updateChart(with updatedViewModels: [ArtistCellViewModel]) {
        
        pieChartItems.removeAll()
        artistCellViewModels.removeAll()
        artistCellViewModels = updatedViewModels
        
        for (index, artistViewModel) in artistCellViewModels.enumerated() {
            let value = CGFloat(artistViewModel.plays)
            let color = colorArray.indices.contains(index) ? colorArray[index] : UIColor.random
            let description = "\(artistViewModel.name)"
            let item = PieChartItem(value: value, color: color, description: description)
            pieChartItems.append(item)
        }
        
        pieChart.reloadData()
        artistTableView.reloadData()
        
    }

    // MARK: - Setup UI
    
    private func demoView(show: Bool) {
        
        // Show the demo chart and explanatory labels for the app stats functionality
        chartDemoView.isHidden = !show
        demoLabel.isHidden = !show
        lastFMLabel.isHidden = !show
        demoTitle.isHidden = !show
        
        if !show {
            // Set placeholders for the overall top artist when there is no logged in user
            resetTopOverallArtist()
        }
        
        // Show the top ovearall artist placeholders
        topArtistImage.isHidden = !show
        topArtistLabel.isHidden = !show
        
        // Hide the scroll view with the real chart and top 5 artists table
        scrollView.isHidden = show
        scrobblesCountLabel.isHidden = show
        scrobblingDateLabel.isHidden = show
    }

    private func configurePieChart() {
        // Add some colors to the color array (alternatively this array can be removed and we can use a random color for each item each time the pie chart is updated instead of these colors)
        colorArray.append(UIColor(red: 0.0596621558070183, green: 0.5609050989151, blue: 0.860916078090668, alpha: 1))
        colorArray.append(UIColor(red: 0.570483803749084, green: 0.287669986486435, blue: 0.753190457820892, alpha: 1))
        colorArray.append(UIColor(red: 0.715113759040833, green: 0.290741920471191, blue: 0.796432793140411, alpha: 1))
        colorArray.append(UIColor(red: 0.378926306962967, green: 0.703457653522491, blue: 0.3383317887783058, alpha: 1))
        colorArray.append(UIColor(red: 0.818354845046997, green: 0.590459525585175, blue: 0.180830329656601, alpha: 1))

        pieChart.dataSource = self
        pieChart.showDescriptionText = true
        pieChart.labelFont = UIFont.systemFont(ofSize: 12)
        let maxRadius = min(pieChart.frame.width, pieChart.frame.height) / 2
        pieChart.outerRadius = maxRadius
    }

    // Show the overall top artist depending on whether there are recent plays for the week or not
    private func showOverallTopArtist(_ show: Bool) {

        chartDemoView.isHidden = !show
        demoLabel.isHidden = !show
        topArtistImage.isHidden = !show
        topArtistLabel.isHidden = !show
        scrollView.isHidden = show
        lastFMLabel.isHidden = show
        demoTitle.isHidden = show
        
        if !show {
            lastFMLabel.isHidden = true
            demoTitle.isHidden = true
        }
    }

    private func resetTopOverallArtist() {
        
        topArtistImage.image = UIImage(named: "Profile")
        topArtistImage.layer.cornerRadius = topArtistImage.frame.size.width / 2
        topArtistImage.layer.masksToBounds = true

        guard let font = UIFont(name: topArtistLabel.font.fontName, size: 15.0) else { return }
        let attribute = [NSAttributedString.Key.font: font]
        let placeholderString = NSAttributedString(string: "Top artist of all time:", attributes: attribute)
        topArtistLabel.attributedText = placeholderString
    }

    // MARK: - Actions

    @IBAction func shareInfogram(_ sender: Any) {
        
        let text = "Captured by MusiChart for iOS"
        
        // Set the scroll view offset to zero to ensure there is no hidden part of the chart
        scrollView.setContentOffset(CGPoint.zero, animated: false)
        // This extension helps make the whole content visible because normaly it's not and you should scroll to view all the info
        let extention = scrollView.contentSize.height - scrollView.frame.size.height + tableViewHeightConstraint.constant/2
        // We change the view frame adding this extension
        view.frame = CGRect(x: view.frame.origin.x, y: view.frame.origin.y, width: view.frame.size.width, height: view.frame.size.height + extention)

        // Hide the button and the background image
        shareButton.alpha = 0
        background.alpha = 0

        if kDebugLog {
            print("self.view:\(view.frame.size.height)")
            print("scrollview:\(scrollView.frame.size.height + extention + scrollView.frame.origin.y)")
        }

        // If capturing the view succeeds then open the activity controller to share the infogram
        if let infogram = view.getImage() {
            
            let activityViewController = UIActivityViewController(activityItems: [text, infogram], applicationActivities: nil)
            activityViewController.excludedActivityTypes = [UIActivity.ActivityType.assignToContact, UIActivity.ActivityType.message, UIActivity.ActivityType.addToReadingList]
            present(activityViewController, animated: true, completion: nil)
        }

        // Get the view back to its normal state removing the extension
        view.frame = CGRect(x: view.frame.origin.x, y: view.frame.origin.y, width: view.frame.size.width, height: view.frame.size.height - extention)

        // Unhide the button and the background
        shareButton.alpha = 1
        background.alpha = 1
    }
    
    // MARK: - deinit
    
    deinit {
        debugPrint("deinit \(type(of: self))")
    }
}

// MARK: - TableViewDataSource

extension ChartsViewController: UITableViewDataSource, UITableViewDelegate {
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return artistCellViewModels.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: "ArtistCell", for: indexPath) as? ArtistCell else {
            return UITableViewCell()
        }

        let index = indexPath.row
        cell.artistViewModel = artistCellViewModels[index]
        if index == artistCellViewModels.count - 1 {
            updateTableViewHeight(cellHeight: cell.frame.height)
        }

        return cell
    }

    func updateTableViewHeight(cellHeight: CGFloat) {
        
        UIView.animate(withDuration: 0, animations: {
            self.artistTableView.layoutIfNeeded()
        }, completion: { _ in
            var heightOfTableView: CGFloat = 0.0
            self.artistCellViewModels.forEach { _ in
                heightOfTableView += cellHeight
            }
            self.tableViewHeightConstraint.constant = heightOfTableView
            self.artistTableView.layoutIfNeeded()
        })
    }
}

// MARK: - ARPieChartDataSource

extension ChartsViewController: ARPieChartDataSource {
    
    func numberOfSlicesInPieChart(_ pieChart: ARPieChart) -> Int {
        return pieChartItems.count
    }

    func pieChart(_ pieChart: ARPieChart, valueForSliceAtIndex index: Int) -> CGFloat {
        let item = pieChartItems[index]
        return item.value
    }

    func pieChart(_ pieChart: ARPieChart, colorForSliceAtIndex index: Int) -> UIColor {
        let item = pieChartItems[index]
        return item.color
    }

    func pieChart(_ pieChart: ARPieChart, descriptionForSliceAtIndex index: Int) -> String {
        let item = pieChartItems[index]
        return item.description ?? ""
    }
}
