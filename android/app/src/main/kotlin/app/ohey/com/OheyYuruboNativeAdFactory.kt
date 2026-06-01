package app.ohey.com

import android.view.LayoutInflater
import android.view.View
import android.widget.Button
import android.widget.ImageView
import android.widget.TextView
import com.google.android.gms.ads.nativead.NativeAd
import com.google.android.gms.ads.nativead.NativeAdView
import io.flutter.plugins.googlemobileads.GoogleMobileAdsPlugin.NativeAdFactory

class OheyYuruboNativeAdFactory(
    private val layoutInflater: LayoutInflater,
) : NativeAdFactory {
    override fun createNativeAd(
        nativeAd: NativeAd,
        customOptions: MutableMap<String, Any>?,
    ): NativeAdView {
        val adView = layoutInflater.inflate(
            R.layout.ohey_yurubo_native_ad,
            null,
        ) as NativeAdView

        val headlineView = adView.findViewById<TextView>(R.id.ad_headline)
        val bodyView = adView.findViewById<TextView>(R.id.ad_body)
        val iconView = adView.findViewById<ImageView>(R.id.ad_icon)
        val advertiserView = adView.findViewById<TextView>(R.id.ad_advertiser)
        val ctaView = adView.findViewById<Button>(R.id.ad_call_to_action)

        adView.headlineView = headlineView
        adView.bodyView = bodyView
        adView.iconView = iconView
        adView.advertiserView = advertiserView
        adView.callToActionView = ctaView

        headlineView.text = nativeAd.headline

        if (nativeAd.body == null) {
            bodyView.visibility = View.GONE
        } else {
            bodyView.text = nativeAd.body
            bodyView.visibility = View.VISIBLE
        }

        if (nativeAd.icon == null) {
            iconView.visibility = View.GONE
        } else {
            iconView.setImageDrawable(nativeAd.icon?.drawable)
            iconView.visibility = View.VISIBLE
        }

        advertiserView.text = nativeAd.advertiser ?: "スポンサー"
        ctaView.text = nativeAd.callToAction ?: "詳しく見る"
        ctaView.isEnabled = false

        adView.setNativeAd(nativeAd)
        return adView
    }
}
