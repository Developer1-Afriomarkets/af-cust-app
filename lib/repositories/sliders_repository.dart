import 'package:afriomarkets_cust_app/data_model/slider_response.dart';
import 'package:afriomarkets_cust_app/services/medusa_service.dart';

class SlidersRepository {
  Future<SliderResponse> getSliders() async {
    final List<Map<String, String>> enrichments = [
      {
         'type': 'INFO',
         'title': 'Discover the Local Pulse',
         'subtitle': 'Explore thousands of verified local artisans instantly.',
         'actionText': 'Get Started',
         'colorHex': '0xFFD32F2F', 
      },
      {
         'type': 'PROMO',
         'title': 'Free Delivery Weekend',
         'subtitle': 'Get your goods shipped free across the region this weekend.',
         'actionText': 'Shop Now',
         'colorHex': '0xFF1976D2',
      },
      {
         'type': 'HIGHLIGHT',
         'title': 'Vendor Spotlight',
         'subtitle': 'See how local weavers are transforming the textile market.',
         'actionText': 'Read Story',
         'colorHex': '0xFF388E3C',
      },
    ];

    try {
      final res = await MedusaService.getCarouselSliders(count: 5);
      if (res.sliders.isNotEmpty && res.sliders.first.photo != null) {
        // Intercept backend image results and dynamically apply informative text templates!
        for (int i = 0; i < res.sliders.length; i++) {
           var e = enrichments[i % enrichments.length];
           res.sliders[i].title = e['title'];
           res.sliders[i].subtitle = e['subtitle'];
           res.sliders[i].type = e['type'];
           res.sliders[i].actionText = e['actionText'];
           res.sliders[i].colorHex = e['colorHex'];
        }
        return res;
      }
    } catch (_) {}

    // Return the incredibly rich contextual informative Banners per user direction mappings!
    return SliderResponse(
      success: true,
      status: 200,
      sliders: enrichments.map((e) => Slider(
           type: e['type'],
           title: e['title'],
           subtitle: e['subtitle'],
           actionText: e['actionText'],
           colorHex: e['colorHex'],
      )).toList()
    );
  }
}
