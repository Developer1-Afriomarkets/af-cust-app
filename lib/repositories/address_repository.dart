import 'package:afriomarkets_cust_app/app_config.dart';
import 'dart:convert';

import 'package:afriomarkets_cust_app/data_model/address_response.dart';
import 'package:afriomarkets_cust_app/data_model/address_add_response.dart';
import 'package:afriomarkets_cust_app/data_model/address_update_response.dart';
import 'package:afriomarkets_cust_app/data_model/address_update_location_response.dart';
import 'package:afriomarkets_cust_app/data_model/address_delete_response.dart';
import 'package:afriomarkets_cust_app/data_model/address_make_default_response.dart';
import 'package:afriomarkets_cust_app/data_model/address_update_in_cart_response.dart';
import 'package:afriomarkets_cust_app/data_model/city_response.dart';
import 'package:afriomarkets_cust_app/data_model/state_response.dart';
import 'package:afriomarkets_cust_app/data_model/country_response.dart';
import 'package:afriomarkets_cust_app/data_model/shipping_cost_response.dart';
import 'package:afriomarkets_cust_app/helpers/shared_value_helper.dart';
import 'package:afriomarkets_cust_app/helpers/safe_api_helper.dart';
import 'package:afriomarkets_cust_app/services/medusa_http_client.dart';

class AddressRepository {
  Future<AddressResponse> getAddressList() async {
    return safeApiCall(() async {
      Uri url =
          Uri.parse("${AppConfig.BASE_URL}/user/shipping/address/${user_id.$}");
      final response = await medusaClient.get(
        url,
        headers: {
          "Content-Type": "application/json",
          "Authorization": "Bearer ${access_token.$}",
          "App-Language": app_language.$,
        },
      );
      guardJson(response);
      return addressResponseFromJson(response.body);
    }, AddressResponse(addresses: [], success: false, status: 0));
  }

  Future<AddressAddResponse> getAddressAddResponse(
      {required String address,
      required int country_id,
      required int state_id,
      required int city_id,
      required String postal_code,
      required String phone}) async {
    return safeApiCall(() async {
      var post_body = jsonEncode({
        "user_id": "${user_id.$}",
        "address": "$address",
        "country_id": "$country_id",
        "state_id": "$state_id",
        "city_id": "$city_id",
        "postal_code": "$postal_code",
        "phone": "$phone"
      });

      Uri url = Uri.parse("${AppConfig.BASE_URL}/user/shipping/create");
      final response = await medusaClient.post(url,
          headers: {
            "Content-Type": "application/json",
            "Authorization": "Bearer ${access_token.$}",
            "App-Language": app_language.$
          },
          body: post_body);
      guardJson(response);

      return addressAddResponseFromJson(response.body);
    }, AddressAddResponse(result: false, message: "API unavailable"));
  }

  Future<AddressUpdateResponse> getAddressUpdateResponse(
      {required int id,
      required String address,
      required int country_id,
      required int state_id,
      required int city_id,
      required String postal_code,
      required String phone}) async {
    return safeApiCall(() async {
      var post_body = jsonEncode({
        "id": "${id}",
        "user_id": "${user_id.$}",
        "address": "$address",
        "country_id": "$country_id",
        "state_id": "$state_id",
        "city_id": "$city_id",
        "postal_code": "$postal_code",
        "phone": "$phone"
      });

      Uri url = Uri.parse("${AppConfig.BASE_URL}/user/shipping/update");
      final response = await medusaClient.post(url,
          headers: {
            "Content-Type": "application/json",
            "Authorization": "Bearer ${access_token.$}",
            "App-Language": app_language.$
          },
          body: post_body);
      guardJson(response);

      return addressUpdateResponseFromJson(response.body);
    }, AddressUpdateResponse(result: false, message: "API unavailable"));
  }

  Future<AddressUpdateLocationResponse> getAddressUpdateLocationResponse(
    int id,
    double latitude,
    double longitude,
  ) async {
    return safeApiCall(() async {
      var post_body = jsonEncode({
        "id": "${id}",
        "user_id": "${user_id.$}",
        "latitude": "$latitude",
        "longitude": "$longitude"
      });

      Uri url = Uri.parse("${AppConfig.BASE_URL}/user/shipping/update-location");
      final response = await medusaClient.post(url,
          headers: {
            "Content-Type": "application/json",
            "Authorization": "Bearer ${access_token.$}",
            "App-Language": app_language.$
          },
          body: post_body);
      guardJson(response);

      return addressUpdateLocationResponseFromJson(response.body);
    }, AddressUpdateLocationResponse(result: false, message: "API unavailable"));
  }

  Future<AddressMakeDefaultResponse> getAddressMakeDefaultResponse(
    int id,
  ) async {
    return safeApiCall(() async {
      var post_body = jsonEncode({
        "user_id": "${user_id.$}",
        "id": "$id",
      });

      Uri url = Uri.parse("${AppConfig.BASE_URL}/user/shipping/make_default");
      final response = await medusaClient.post(url,
          headers: {
            "Content-Type": "application/json",
            "Authorization": "Bearer ${access_token.$}"
          },
          body: post_body);
      guardJson(response);

      return addressMakeDefaultResponseFromJson(response.body);
    }, AddressMakeDefaultResponse(result: false, message: "API unavailable"));
  }

  Future<AddressDeleteResponse> getAddressDeleteResponse(
    int id,
  ) async {
    return safeApiCall(() async {
      Uri url = Uri.parse("${AppConfig.BASE_URL}/user/shipping/delete/$id");
      final response = await medusaClient.get(
        url,
        headers: {
          "Authorization": "Bearer ${access_token.$}",
          "App-Language": app_language.$
        },
      );
      guardJson(response);

      return addressDeleteResponseFromJson(response.body);
    }, AddressDeleteResponse(result: false, message: "API unavailable"));
  }

  Future<CityResponse> getCityListByState({state_id = 0, name = ""}) async {
    return safeApiCall(() async {
      Uri url = Uri.parse(
          "${AppConfig.BASE_URL}/cities-by-state/${state_id}?name=${name}");
      final response = await medusaClient.get(url);
      guardJson(response);

      return cityResponseFromJson(response.body);
    }, CityResponse(cities: [], success: false, status: 0));
  }

  Future<MyStateResponse> getStateListByCountry(
      {country_id = 0, name = ""}) async {
    return safeApiCall(() async {
      Uri url = Uri.parse(
          "${AppConfig.BASE_URL}/states-by-country/${country_id}?name=${name}");
      final response = await medusaClient.get(url);
      guardJson(response);
      return myStateResponseFromJson(response.body);
    }, MyStateResponse(states: [], success: false, status: 0));
  }

  Future<CountryResponse> getCountryList({name = ""}) async {
    return safeApiCall(() async {
      Uri url = Uri.parse("${AppConfig.BASE_URL}/countries?name=${name}");
      final response = await medusaClient.get(url);
      guardJson(response);
      return countryResponseFromJson(response.body);
    }, CountryResponse(countries: [], success: false, status: 0));
  }

  Future<ShippingCostResponse> getShippingCostResponse(
      int owner_id, int user_id, int address_id) async {
    return safeApiCall(() async {
      var post_body =
          jsonEncode({"user_id": "$user_id", "address_id": "$address_id"});

      Uri url = Uri.parse("${AppConfig.BASE_URL}/shipping_cost");
      final response = await medusaClient.post(url,
          headers: {
            "Content-Type": "application/json",
            "Authorization": "Bearer ${access_token.$}",
            "App-Language": app_language.$
          },
          body: post_body);
      guardJson(response);

      return shippingCostResponseFromJson(response.body);
    }, ShippingCostResponse(result: false));
  }

  Future<AddressUpdateInCartResponse> getAddressUpdateInCartResponse(
    int address_id,
  ) async {
    return safeApiCall(() async {
      var post_body =
          jsonEncode({"address_id": "${address_id}", "user_id": "${user_id.$}"});

      Uri url = Uri.parse("${AppConfig.BASE_URL}/update-address-in-cart");
      final response = await medusaClient.post(url,
          headers: {
            "Content-Type": "application/json",
            "Authorization": "Bearer ${access_token.$}",
            "App-Language": app_language.$
          },
          body: post_body);
      guardJson(response);

      return addressUpdateInCartResponseFromJson(response.body);
    }, AddressUpdateInCartResponse(result: false, message: "API unavailable"));
  }


}
