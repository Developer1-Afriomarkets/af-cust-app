import 'package:afriomarkets_cust_app/data_model/category_response.dart';
import 'package:afriomarkets_cust_app/services/medusa_service.dart';

class CategoryRepository {
  Future<CategoryResponse> getCategories({parent_id = 0}) async {
    return MedusaService.getCategoriesMapped();
  }

  Future<CategoryResponse> getFeturedCategories() async {
    return MedusaService.getCategoriesMapped();
  }

  Future<CategoryResponse> getTopCategories() async {
    return MedusaService.getCategoriesMapped();
  }

  Future<CategoryResponse> getFilterPageCategories() async {
    return MedusaService.getCategoriesMapped();
  }
}
