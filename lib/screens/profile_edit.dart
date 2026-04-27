import 'package:flutter/material.dart';
import 'package:afriomarkets_cust_app/my_theme.dart';
import 'package:afriomarkets_cust_app/helpers/shared_value_helper.dart';
import 'package:afriomarkets_cust_app/helpers/path_helper.dart';
import 'package:afriomarkets_cust_app/custom/toast_component.dart';

import 'package:afriomarkets_cust_app/custom/input_decorations.dart';
import 'package:afriomarkets_cust_app/repositories/profile_repository.dart';
import 'dart:io';
import 'dart:convert';
import 'package:image_picker/image_picker.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:flutter/cupertino.dart';
import 'package:afriomarkets_cust_app/helpers/file_helper.dart';
import 'package:afriomarkets_cust_app/l10n/app_localizations.dart';

class ProfileEdit extends StatefulWidget {
  @override
  _ProfileEditState createState() => _ProfileEditState();
}

class _ProfileEditState extends State<ProfileEdit> {
  ScrollController _mainScrollController = ScrollController();

  TextEditingController _nameController =
      TextEditingController(text: "${user_name.$}");
  TextEditingController _passwordController = TextEditingController();
  TextEditingController _passwordConfirmController = TextEditingController();

  //for image uploading
  final ImagePicker _picker = ImagePicker();
  XFile? _file;

  chooseAndUploadImage(context) async {
    var status = await Permission.photos.request();

    if (status.isDenied) {
      // We didn't ask for permission yet.
      showDialog(
          context: context,
          builder: (BuildContext context) => CupertinoAlertDialog(
                title:
                    Text(AppLocalizations.of(context)!.common_photo_permission),
                content: Text(
                    AppLocalizations.of(context)!.common_app_needs_permission),
                actions: <Widget>[
                  CupertinoDialogAction(
                    child: Text(AppLocalizations.of(context)!.common_deny),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                  CupertinoDialogAction(
                    child: Text(AppLocalizations.of(context)!.common_settings),
                    onPressed: () => openAppSettings(),
                  ),
                ],
              ));
    } else if (status.isRestricted) {
      ToastComponent.showDialog(
          AppLocalizations.of(context)!.common_give_photo_permission, context);
    } else if (status.isGranted) {
      //file = await ImagePicker.pickImage(source: ImageSource.camera);
      _file = await _picker.pickImage(source: ImageSource.gallery);

      final file = _file;
      if (file == null) {
        ToastComponent.showDialog(
            AppLocalizations.of(context)!.common_no_file_chosen, context);
        return;
      }

      //return;
      String base64Image = FileHelper.getBase64FormateFile(file.path);
      String fileName = file.path.split("/").last;

      var profileImageUpdateResponse =
          await ProfileRepository().getProfileImageUpdateResponse(
        base64Image,
        fileName,
      );

      if (profileImageUpdateResponse.result == false) {
        ToastComponent.showDialog(
            profileImageUpdateResponse.message ?? "", context);
        return;
      } else {
        ToastComponent.showDialog(
            profileImageUpdateResponse.message ?? "", context);

        avatar_original.$ = profileImageUpdateResponse.path ?? "";
        setState(() {});
      }
    }
  }

  Future<void> _onPageRefresh() async {}

  onPressUpdate() async {
    var name = _nameController.text.toString();
    var password = _passwordController.text.toString();
    var password_confirm = _passwordConfirmController.text.toString();

    var change_password = password != "" ||
        password_confirm !=
            ""; // if both fields are empty we will not change user's password

    if (name == "") {
      ToastComponent.showDialog(
          AppLocalizations.of(context)!.profile_edit_screen_name_warning,
          context);
      return;
    }
    if (change_password && password == "") {
      ToastComponent.showDialog(
          AppLocalizations.of(context)!.profile_edit_screen_password_warning,
          context);
      return;
    }
    if (change_password && password_confirm == "") {
      ToastComponent.showDialog(
          AppLocalizations.of(context)!
              .profile_edit_screen_password_confirm_warning,
          context);
      return;
    }
    if (change_password && password.length < 6) {
      ToastComponent.showDialog(
          AppLocalizations.of(context)!
              .password_otp_screen_password_length_warning,
          context);
      return;
    }
    if (change_password && password != password_confirm) {
      ToastComponent.showDialog(
          AppLocalizations.of(context)!
              .profile_edit_screen_password_match_warning,
          context);
      return;
    }

    var profileUpdateResponse =
        await ProfileRepository().getProfileUpdateResponse(
      name,
      change_password ? password : "",
    );

    if (profileUpdateResponse.result == false) {
      ToastComponent.showDialog(profileUpdateResponse.message ?? "", context);
    } else {
      ToastComponent.showDialog(profileUpdateResponse.message ?? "", context);

      user_name.$ = name;
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: app_language_rtl.$ ? TextDirection.rtl : TextDirection.ltr,
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: buildAppBar(context),
        body: MyTheme.brandBackground(context: context, child: buildBody(context)),
      ),
    );
  }

  AppBar buildAppBar(BuildContext context) {
    return AppBar(
      backgroundColor: Colors.transparent,
      centerTitle: true,
      leading: Builder(
        builder: (context) => IconButton(
          icon: Icon(Icons.arrow_back, color: MyTheme.primaryText(context)),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      title: Text(
        AppLocalizations.of(context)?.profile_edit_screen_edit_profile ??
            "Edit Profile",
        style: TextStyle(fontSize: 16, color: MyTheme.primaryText(context), fontWeight: FontWeight.bold),
      ),
      elevation: 0.0,
      titleSpacing: 0,
    );
  }

  buildBody(context) {
    if (is_logged_in.$ == false) {
      return Container(
          height: 100,
          child: Center(
              child: Text(
            AppLocalizations.of(context)?.profile_edit_screen_login_warning ??
                "Please login to see this",
            style: TextStyle(color: MyTheme.font_grey),
          )));
    } else {
      return RefreshIndicator(
        color: MyTheme.accent_color,
        backgroundColor: Colors.white,
        onRefresh: _onPageRefresh,
        displacement: 10,
        child: CustomScrollView(
          controller: _mainScrollController,
          physics: const BouncingScrollPhysics(
              parent: AlwaysScrollableScrollPhysics()),
          slivers: [
            SliverList(
              delegate: SliverChildListDelegate([
                buildTopSection(),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  child: Divider(
                    height: 24,
                  ),
                ),
                buildProfileForm(context)
              ]),
            )
          ],
        ),
      );
    }
  }

  buildTopSection() {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.only(top: 16.0, bottom: 8.0),
          child: Stack(
            children: [
              Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(100),
                  border: Border.all(
                      color: Color.fromRGBO(112, 112, 112, .3), width: 2),
                  //shape: BoxShape.rectangle,
                ),
                child: ClipRRect(
                    clipBehavior: Clip.hardEdge,
                    borderRadius: BorderRadius.all(Radius.circular(100.0)),
                    child: FadeInImage.assetNetwork(
                      placeholder: 'assets/placeholder.png',
                      image: PathHelper.getImageUrlSafe("${avatar_original.$}"),
                      fit: BoxFit.fill,
                    )),
              ),
              Positioned(
                right: 8,
                bottom: 8,
                child: SizedBox(
                  width: 24,
                  height: 24,
                  child: TextButton(
                    child: Icon(
                      Icons.edit,
                      color: MyTheme.font_grey,
                      size: 14,
                    ),
                    style: TextButton.styleFrom(
                      padding: EdgeInsets.all(0),
                      backgroundColor: MyTheme.light_grey,
                      shape: CircleBorder(
                        side: new BorderSide(
                            color: MyTheme.light_grey, width: 1.0),
                      ),
                    ),
                    onPressed: () {
                      chooseAndUploadImage(context);
                    },
                  ),
                ),
              )
            ],
          ),
        ),
      ],
    );
  }

  buildProfileForm(context) {
    return Padding(
      padding:
          const EdgeInsets.only(top: 8.0, bottom: 8.0, left: 16.0, right: 16.0),
      child: Container(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.only(bottom: 8.0),
              child: Text(
                AppLocalizations.of(context)
                        ?.profile_edit_screen_basic_information ??
                    "Basic Information",
                style: TextStyle(
                    color: MyTheme.primaryText(context),
                    fontWeight: FontWeight.w700,
                    fontSize: 14.0),
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(bottom: 4.0),
              child: Text(
                AppLocalizations.of(context)?.profile_edit_screen_name ??
                    "Name",
                style: TextStyle(
                    color: MyTheme.accent_color, fontWeight: FontWeight.w600),
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(bottom: 8.0),
              child: Container(
                height: 48,
                child: TextField(
                  controller: _nameController,
                  autofocus: false,
                  style: TextStyle(color: MyTheme.primaryText(context)),
                  decoration: InputDecorations.buildInputDecoration_1(context,
                      hint_text: "John Doe"),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(bottom: 4.0),
              child: Text(
                AppLocalizations.of(context)?.profile_edit_screen_password ??
                    "Password",
                style: TextStyle(
                    color: MyTheme.accent_color, fontWeight: FontWeight.w600),
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(bottom: 8.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Container(
                    height: 48,
                    child: TextField(
                      controller: _passwordController,
                      autofocus: false,
                      obscureText: true,
                      enableSuggestions: false,
                      autocorrect: false,
                      style: TextStyle(color: MyTheme.primaryText(context)),
                      decoration: InputDecorations.buildInputDecoration_1(context,
                          hint_text: "• • • • • • • •"),
                    ),
                  ),
                  Text(
                    AppLocalizations.of(context)
                            ?.profile_edit_screen_password_length_recommendation ??
                        "Min 6 chars",
                    style: TextStyle(
                        color: MyTheme.secondaryText(context).withOpacity(0.6),
                        fontSize: 11,
                        fontStyle: FontStyle.italic),
                  )
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(bottom: 4.0),
              child: Text(
                AppLocalizations.of(context)
                        ?.profile_edit_screen_retype_password ??
                    "Retype Password",
                style: TextStyle(
                    color: MyTheme.accent_color, fontWeight: FontWeight.w600),
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(bottom: 8.0),
              child: Container(
                height: 48,
                child: TextField(
                  controller: _passwordConfirmController,
                  autofocus: false,
                  obscureText: true,
                  enableSuggestions: false,
                  autocorrect: false,
                  style: TextStyle(color: MyTheme.primaryText(context)),
                  decoration: InputDecorations.buildInputDecoration_1(context,
                      hint_text: "• • • • • • • •"),
                ),
              ),
            ),
            Row(
              children: [
                Spacer(),
                Padding(
                  padding: const EdgeInsets.only(top: 16.0),
                  child: Container(
                    width: 120,
                    height: 36,
                    decoration: BoxDecoration(
                        border:
                            Border.all(color: MyTheme.textfield_grey, width: 1),
                        borderRadius:
                            const BorderRadius.all(Radius.circular(8.0))),
                    child: TextButton(
                      style: TextButton.styleFrom(
                        minimumSize:
                            Size(MediaQuery.of(context).size.width, 50),
                        backgroundColor: MyTheme.accent_color,
                        shape: RoundedRectangleBorder(
                            borderRadius:
                                const BorderRadius.all(Radius.circular(8.0))),
                      ),
                      child: Text(
                        AppLocalizations.of(context)
                                ?.profile_edit_screen_btn_update_profile ??
                            "Update Profile",
                        style: TextStyle(
                            color: Colors.white,
                            fontSize: 14,
                            fontWeight: FontWeight.w700),
                      ),
                      onPressed: () {
                        onPressUpdate();
                      },
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
