import 'package:afriomarkets_cust_app/app_config.dart';
import 'package:afriomarkets_cust_app/data_model/search_suggestion_response.dart';
import 'package:afriomarkets_cust_app/services/medusa_http_client.dart';
import 'package:afriomarkets_cust_app/helpers/safe_api_helper.dart';

class SearchRepository {
  Future<List<SearchSuggestionResponse>> getSearchSuggestionListResponse(
      {query_key = "", type = "product"}) async {
    return safeApiCall(() async {
      Uri url = Uri.parse("${AppConfig.BASE_URL}/search-suggestions?query=$query_key");
      final response = await medusaClient.get(url);
      guardJson(response);
      return searchSuggestionResponseFromJson(response.body);
    }, []);
  }
}
