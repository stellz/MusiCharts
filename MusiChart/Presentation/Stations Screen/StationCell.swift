import UIKit

class StationCell: UITableViewCell {

    var viewModel: StationCellViewModel? {
        didSet {
            configureStationCell()
        }
    }
    
    @IBOutlet var stationNameLabel: UILabel!
    @IBOutlet var stationDescLabel: UILabel!
    @IBOutlet var stationImageView: UIImageView!

    var downloadTask: URLSessionDownloadTask?

    override func awakeFromNib() {
        super.awakeFromNib()

        // Set table selection color
        let selectedView = UIView(frame: CGRect.zero)
        selectedView.backgroundColor = UIColor(red: 78/255, green: 82/255, blue: 93/255, alpha: 0.6)
        selectedBackgroundView  = selectedView
    }

    fileprivate func configureStationCell() {
        guard let viewModel = viewModel else { return }
      
        stationNameLabel.text = viewModel.stationName
        stationDescLabel.text = viewModel.stationDescription

        let imageURL = viewModel.imageURL
        
        //If the image url is actual url address
        if imageURL.contains("http") {
            // Try to make an url object
            if let url = URL(string: viewModel.imageURL) {
                
                //If success - download and cache the radio station image
                stationImageView.sd_setImage(with: url, placeholderImage: UIImage(named: "StationImage"), options: [.continueInBackground, .progressiveDownload])
            }
            // If not - and if the imageURL string is not empty
        } else if !imageURL.isEmpty {
            // Set the image by it's path
            stationImageView.image = UIImage(named: imageURL)
            
            // If the imageURL is empty
        } else {
            // Use the default asset provided in the project
            stationImageView.image = UIImage(named: "StationImage")
        }

        // If after all the image on the view is nil
        if stationImageView.image == nil {
            // Set it using the default asset provided in the project
            stationImageView.image = UIImage(named: "StationImage")
        }

        // Apply a drop shadow to look more fancy
        stationImageView.applyShadow()
    }

    // Before reusing the cell clean up the previous cell content
    override func prepareForReuse() {
        super.prepareForReuse()

        downloadTask?.cancel()
        downloadTask = nil
        stationNameLabel.text  = nil
        stationDescLabel.text  = nil
        stationImageView.image = nil
    }
}
