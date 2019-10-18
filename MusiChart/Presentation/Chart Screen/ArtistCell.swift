//
//  ArtistTableViewCell.swift
//  MusiChart
//
//  Created by Stella on 11.05.18.
//  Copyright © 2018 Magpie Studio Ltd. All rights reserved.
//

import Foundation

class ArtistCell: UITableViewCell {

    @IBOutlet var artistImageView: UIImageView!
    @IBOutlet var playcountLabel: UILabel!
    @IBOutlet var artistNameLabel: UILabel!

    var artistViewModel: ArtistCellViewModel? {
        didSet {
            configureStationCell()
        }
    }
    
    fileprivate func configureStationCell() {
        guard let artistViewModel = artistViewModel else { return }
        
        artistNameLabel.text = artistViewModel.name
        
        let playString = artistViewModel.plays == 1 ? "play" : "plays"
        playcountLabel.text = "\(artistViewModel.plays) " + playString
   
        if let url = URL(string: artistViewModel.imageURL) {
            //Download the image, cache and set it to the cell's imageView.image
            artistImageView.sd_setImage(with: url, placeholderImage: UIImage(named: "Profile"), options: [.continueInBackground, .progressiveDownload])
        } else {
            // Set the placeholder image if there is no artist image on the web
            artistImageView.image = UIImage(named: "Profile")
        }
        
        // Make beautiful rounded corners
        artistImageView.layer.cornerRadius = artistImageView.frame.size.width / 2
        artistImageView.layer.masksToBounds = true
    }

    // Before reusing the cell clean up the previous cell content
    override func prepareForReuse() {
        super.prepareForReuse()

        playcountLabel.text  = nil
        artistNameLabel.text  = nil
        artistImageView.image = nil
    }
}
