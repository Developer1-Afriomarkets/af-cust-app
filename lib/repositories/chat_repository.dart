import 'package:afriomarkets_cust_app/app_config.dart';
import 'package:afriomarkets_cust_app/data_model/conversation_response.dart';
import 'package:afriomarkets_cust_app/data_model/message_response.dart';
import 'package:afriomarkets_cust_app/data_model/conversation_create_response.dart';
import 'dart:convert';
import 'package:afriomarkets_cust_app/services/medusa_http_client.dart';
import 'package:afriomarkets_cust_app/helpers/shared_value_helper.dart';
import 'package:afriomarkets_cust_app/helpers/safe_api_helper.dart';

class ChatRepository {
  Future<ConversationResponse> getConversationResponse({page = 1}) async {
    return safeApiCall(() async {
      Uri url = Uri.parse("${AppConfig.BASE_URL}/chat/conversations/${user_id.$}");
      final response = await medusaClient.get(url, headers: {
        "Authorization": "Bearer ${access_token.$}",
        "App-Language": app_language.$,
      });
      guardJson(response);
      return conversationResponseFromJson(response.body);
    }, ConversationResponse(conversation_item_list: [], success: false, status: 0));
  }

  Future<MessageResponse> getMessageResponse(
      {required conversation_id, page = 1}) async {
    return safeApiCall(() async {
      Uri url = Uri.parse("${AppConfig.BASE_URL}/chat/messages/$conversation_id");
      final response = await medusaClient.get(url, headers: {
        "Authorization": "Bearer ${access_token.$}",
        "App-Language": app_language.$,
      });
      guardJson(response);
      return messageResponseFromJson(response.body);
    }, MessageResponse(messages: [], success: false, status: 0));
  }

  Future<MessageResponse> getInserMessageResponse(
      {required conversation_id, required String message}) async {
    return safeApiCall(() async {
      var post_body = jsonEncode({
        "user_id": "${user_id.$}",
        "conversation_id": "${conversation_id}",
        "message": "${message}"
      });

      Uri url = Uri.parse("${AppConfig.BASE_URL}/chat/insert-message");
      final response = await medusaClient.post(url,
          headers: {
            "Content-Type": "application/json",
            "Authorization": "Bearer ${access_token.$}",
            "App-Language": app_language.$
          },
          body: post_body);
      guardJson(response);
      return messageResponseFromJson(response.body);
    }, MessageResponse(messages: [], success: false, status: 0));
  }

  Future<MessageResponse> getNewMessageResponse(
      {required conversation_id, required last_message_id}) async {
    return safeApiCall(() async {
      Uri url = Uri.parse(
          "${AppConfig.BASE_URL}/chat/get-new-messages/${conversation_id}/${last_message_id}");
      final response = await medusaClient.get(
        url,
        headers: {
          "Authorization": "Bearer ${access_token.$}",
          "App-Language": app_language.$
        },
      );
      guardJson(response);
      return messageResponseFromJson(response.body);
    }, MessageResponse(messages: [], success: false, status: 0));
  }

  Future<ConversationCreateResponse> getCreateConversationResponse(
      {required product_id,
      required String title,
      required String message}) async {
    return safeApiCall(() async {
      var post_body = jsonEncode({
        "user_id": "${user_id.$}",
        "product_id": "${product_id}",
        "title": "${title}",
        "message": "${message}"
      });

      Uri url = Uri.parse("${AppConfig.BASE_URL}/chat/create-conversation");
      final response = await medusaClient.post(url,
          headers: {
            "Content-Type": "application/json",
            "Authorization": "Bearer ${access_token.$}",
            "App-Language": app_language.$
          },
          body: post_body);
      guardJson(response);
      return conversationCreateResponseFromJson(response.body);
    }, ConversationCreateResponse(result: false, conversation_id: 0));
  }
}
