import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:flutter/services.dart';
import 'package:afriomarkets_cust_app/my_theme.dart';
import 'package:afriomarkets_cust_app/helpers/shared_value_helper.dart';
import 'package:afriomarkets_cust_app/l10n/app_localizations.dart';

class VideoDescription extends StatefulWidget {
  final String url;

  VideoDescription({Key? key, this.url = ""}) : super(key: key);

  @override
  _VideoDescriptionState createState() => _VideoDescriptionState();
}

class _VideoDescriptionState extends State<VideoDescription> {
  late WebViewController _webViewController;

  @override
  void initState() {
    super.initState();
    SystemChrome.setPreferredOrientations(
        [DeviceOrientation.landscapeLeft, DeviceOrientation.landscapeRight]);

    _webViewController = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..loadRequest(Uri.parse(widget.url));
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: true,
      onPopInvoked: (didPop) async {
        if (MediaQuery.of(context).orientation == Orientation.landscape) {
          SystemChrome.setPreferredOrientations(
              [DeviceOrientation.portraitUp, DeviceOrientation.portraitDown]);
        }
      },
      child: Directionality(
        textDirection:
            app_language_rtl.$ ? TextDirection.rtl : TextDirection.ltr,
        child: Scaffold(
          backgroundColor: Colors.white,
          body: buildBody(),
        ),
      ),
    );
  }

  buildBody() {
    return SizedBox.expand(
      child: Stack(
        children: [
          WebViewWidget(controller: _webViewController),
          Align(
            alignment: app_language_rtl.$
                ? Alignment.centerRight
                : Alignment.centerLeft,
            child: Container(
              decoration: ShapeDecoration(
                color: MyTheme.medium_grey_50,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.only(
                    topRight: Radius.circular(25),
                    bottomRight: Radius.circular(25),
                  ),
                ),
              ),
              width: 40,
              height: 40,
              child: IconButton(
                icon: Icon(Icons.arrow_back, color: MyTheme.white),
                onPressed: () {
                  if (MediaQuery.of(context).orientation ==
                      Orientation.landscape) {
                    SystemChrome.setPreferredOrientations([
                      DeviceOrientation.portraitUp,
                      DeviceOrientation.portraitDown
                    ]);
                  }
                  return Navigator.of(context).pop();
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}
