import Flutter
import GoogleMobileAds
import UIKit
import google_mobile_ads

final class OheyYuruboNativeAdFactory: NSObject, FLTNativeAdFactory {
  func createNativeAd(
    _ nativeAd: NativeAd,
    customOptions: [AnyHashable: Any]? = nil
  ) -> NativeAdView? {
    let style = customOptions?["style"] as? String
    let isFeedBlock = style == "feed_block"

    let adView = NativeAdView()
    adView.backgroundColor = UIColor(red: 0.05, green: 0.09, blue: 0.14, alpha: 0.94)
    adView.layer.cornerRadius = isFeedBlock ? 0 : 30
    adView.layer.masksToBounds = true

    let prLabel = UILabel()
    prLabel.text = "PR"
    prLabel.textColor = UIColor(red: 0.06, green: 0.09, blue: 0.13, alpha: 1)
    prLabel.backgroundColor = UIColor(red: 0.61, green: 0.95, blue: 0.10, alpha: 1)
    prLabel.font = UIFont.systemFont(ofSize: 11, weight: .black)
    prLabel.textAlignment = .center
    prLabel.layer.cornerRadius = 10
    prLabel.layer.masksToBounds = true
    prLabel.translatesAutoresizingMaskIntoConstraints = false

    let iconView = UIImageView()
    iconView.contentMode = .scaleAspectFill
    iconView.layer.cornerRadius = 18
    iconView.layer.masksToBounds = true
    iconView.translatesAutoresizingMaskIntoConstraints = false

    let headlineLabel = UILabel()
    headlineLabel.textColor = .white
    headlineLabel.font = UIFont.systemFont(ofSize: 17, weight: .black)
    headlineLabel.numberOfLines = 1
    headlineLabel.translatesAutoresizingMaskIntoConstraints = false

    let bodyLabel = UILabel()
    bodyLabel.textColor = UIColor.white.withAlphaComponent(0.70)
    bodyLabel.font = UIFont.systemFont(ofSize: 12, weight: .bold)
    bodyLabel.numberOfLines = 1
    bodyLabel.lineBreakMode = .byTruncatingTail
    bodyLabel.translatesAutoresizingMaskIntoConstraints = false

    let advertiserLabel = UILabel()
    advertiserLabel.textColor = UIColor.white.withAlphaComponent(0.52)
    advertiserLabel.font = UIFont.systemFont(ofSize: 11, weight: .bold)
    advertiserLabel.numberOfLines = 1
    advertiserLabel.translatesAutoresizingMaskIntoConstraints = false

    let ctaButton = UIButton(type: .system)
    ctaButton.setTitleColor(UIColor(red: 0.06, green: 0.09, blue: 0.13, alpha: 1), for: .normal)
    ctaButton.backgroundColor = UIColor(red: 0.75, green: 0.55, blue: 1.0, alpha: 1)
    ctaButton.titleLabel?.font = UIFont.systemFont(ofSize: 13, weight: .black)
    ctaButton.layer.cornerRadius = 16
    ctaButton.translatesAutoresizingMaskIntoConstraints = false
    ctaButton.isUserInteractionEnabled = false

    adView.addSubview(prLabel)
    adView.addSubview(iconView)
    adView.addSubview(headlineLabel)
    adView.addSubview(bodyLabel)
    adView.addSubview(advertiserLabel)
    adView.addSubview(ctaButton)

    NSLayoutConstraint.activate([
      prLabel.leadingAnchor.constraint(equalTo: adView.leadingAnchor, constant: 16),
      prLabel.topAnchor.constraint(equalTo: adView.topAnchor, constant: 14),
      prLabel.widthAnchor.constraint(greaterThanOrEqualToConstant: 34),
      prLabel.heightAnchor.constraint(equalToConstant: 21),

      iconView.leadingAnchor.constraint(equalTo: adView.leadingAnchor, constant: 16),
      iconView.topAnchor.constraint(equalTo: prLabel.bottomAnchor, constant: 18),
      iconView.widthAnchor.constraint(equalToConstant: 48),
      iconView.heightAnchor.constraint(equalToConstant: 48),

      headlineLabel.leadingAnchor.constraint(equalTo: iconView.trailingAnchor, constant: 12),
      headlineLabel.trailingAnchor.constraint(equalTo: adView.trailingAnchor, constant: -16),
      headlineLabel.topAnchor.constraint(equalTo: iconView.topAnchor, constant: 1),

      bodyLabel.leadingAnchor.constraint(equalTo: headlineLabel.leadingAnchor),
      bodyLabel.trailingAnchor.constraint(equalTo: headlineLabel.trailingAnchor),
      bodyLabel.topAnchor.constraint(equalTo: headlineLabel.bottomAnchor, constant: 4),
      bodyLabel.bottomAnchor.constraint(lessThanOrEqualTo: ctaButton.topAnchor, constant: -8),

      advertiserLabel.leadingAnchor.constraint(equalTo: adView.leadingAnchor, constant: 16),
      advertiserLabel.trailingAnchor.constraint(lessThanOrEqualTo: iconView.trailingAnchor),
      advertiserLabel.bottomAnchor.constraint(equalTo: adView.bottomAnchor, constant: -18),

      ctaButton.leadingAnchor.constraint(equalTo: headlineLabel.leadingAnchor),
      ctaButton.trailingAnchor.constraint(equalTo: adView.trailingAnchor, constant: -16),
      ctaButton.bottomAnchor.constraint(equalTo: adView.bottomAnchor, constant: -12),
      ctaButton.heightAnchor.constraint(equalToConstant: 32),
    ])

    headlineLabel.text = nativeAd.headline
    bodyLabel.text = nativeAd.body
    bodyLabel.isHidden = nativeAd.body == nil
    advertiserLabel.text = nativeAd.advertiser ?? "スポンサー"
    ctaButton.setTitle(nativeAd.callToAction ?? "詳しく見る", for: .normal)
    if let image = nativeAd.icon?.image {
      iconView.image = image
      iconView.isHidden = false
    } else {
      iconView.isHidden = true
    }

    adView.headlineView = headlineLabel
    adView.bodyView = bodyLabel
    adView.iconView = iconView
    adView.advertiserView = advertiserLabel
    adView.callToActionView = ctaButton
    adView.nativeAd = nativeAd
    return adView
  }
}
