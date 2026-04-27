import 'package:flutter/material.dart';
import 'package:afriomarkets_cust_app/my_theme.dart';
import 'package:afriomarkets_cust_app/ui_sections/animated_sidebar.dart';
import 'package:afriomarkets_cust_app/custom/toast_component.dart';

import 'package:afriomarkets_cust_app/data_model/category_response.dart';
import 'package:afriomarkets_cust_app/screens/category_products.dart';
import 'package:afriomarkets_cust_app/repositories/category_repository.dart';
import 'package:shimmer/shimmer.dart';
import 'package:afriomarkets_cust_app/helpers/path_helper.dart';
import 'package:afriomarkets_cust_app/helpers/shared_value_helper.dart';
import 'package:afriomarkets_cust_app/l10n/app_localizations.dart';
import 'package:afriomarkets_cust_app/screens/filter.dart';

class CategoryList extends StatefulWidget {
  CategoryList(
      {Key? key,
      this.parent_category_id = 0,
      this.parent_category_name = "",
      this.is_base_category = false,
      this.is_top_category = false})
      : super(key: key);

  final int parent_category_id;
  final String parent_category_name;
  final bool is_base_category;
  final bool is_top_category;

  @override
  _CategoryListState createState() => _CategoryListState();
}

class _CategoryListState extends State<CategoryList> {
  final GlobalKey<ScaffoldState> _scaffoldKey = new GlobalKey<ScaffoldState>();

  @override
  Widget build(BuildContext context) {
    return MyTheme.brandBackground(
      context: context,
      child: Directionality(
        textDirection:
            app_language_rtl.$ ? TextDirection.rtl : TextDirection.ltr,
        child: Scaffold(
            key: _scaffoldKey,
            backgroundColor: Colors.transparent,
            appBar: buildAppBar(context),
            body: Stack(children: [
              CustomScrollView(
                slivers: [
                  SliverList(
                      delegate: SliverChildListDelegate([
                    buildCategoryList(),
                    Container(
                      height: widget.is_base_category ? 60 : 90,
                    )
                  ]))
                ],
              ),
              Align(
                alignment: Alignment.bottomCenter,
                child: widget.is_base_category || widget.is_top_category
                    ? Container(
                        height: 0,
                      )
                    : buildBottomContainer(),
              )
            ])),
      ),
    );
  }

  AppBar buildAppBar(BuildContext context) {
    final isDark = MyTheme.isDark(context);
    return AppBar(
      backgroundColor: isDark ? Colors.transparent : MyTheme.accent_color,
      flexibleSpace: Container(
        decoration: BoxDecoration(
          gradient:
              isDark ? MyTheme.appBarGradientDark : MyTheme.appBarGradient,
        ),
        child: Stack(
          children: [
            Positioned.fill(
              child: CustomPaint(
                painter: AfricanSilhouettePainter(
                  baseColor: MyTheme.golden,
                  opacity: isDark ? 0.2 : 0.3,
                ),
              ),
            ),
          ],
        ),
      ),
      toolbarHeight: 90,
      leading: Padding(
        padding: const EdgeInsets.only(top: 8.0),
        child: widget.is_base_category
            ? GestureDetector(
                onTap: () {
                  AnimatedSidebarScaffold.of(context)?.toggleMenu();
                },
                child: Builder(
                  builder: (context) => Padding(
                    padding: const EdgeInsets.symmetric(
                        vertical: 18.0, horizontal: 0.0),
                    child: IconButton(
                      icon: Image.asset(
                        'assets/hamburger.png',
                        height: 16,
                        color: Colors.white,
                      ),
                      onPressed: () {
                        AnimatedSidebarScaffold.of(context)?.toggleMenu();
                      },
                    ),
                  ),
                ),
              )
            : Builder(
                builder: (context) => IconButton(
                  icon: const Icon(Icons.arrow_back, color: Colors.white),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ),
      ),
      title: Padding(
        padding: const EdgeInsets.only(top: 12.0),
        child: GestureDetector(
          onTap: () {
            Navigator.push(context, MaterialPageRoute(builder: (context) {
              return Filter();
            }));
          },
          child: Container(
            height: 38,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(isDark ? 0.08 : 0.12),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: Colors.white.withOpacity(0.1),
                width: 1,
              ),
            ),
            child: Row(
              children: [
                const SizedBox(width: 14),
                Icon(Icons.search,
                    color: Colors.white.withOpacity(0.7), size: 18),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    getAppBarTitle(),
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.7),
                      fontSize: 13,
                      fontWeight: FontWeight.w400,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
      elevation: 0.0,
      titleSpacing: 0,
      actions: [
        const SizedBox(width: 16),
      ],
    );
  }

  String getAppBarTitle() {
    String name = widget.parent_category_name == ""
        ? (widget.is_top_category
            ? AppLocalizations.of(context)!.category_list_screen_top_categories
            : AppLocalizations.of(context)!.category_list_screen_categories)
        : widget.parent_category_name;

    return name;
  }

  buildCategoryList() {
    var future = widget.is_top_category
        ? CategoryRepository().getTopCategories()
        : CategoryRepository()
            .getCategories(parent_id: widget.parent_category_id);
    return FutureBuilder<CategoryResponse>(
        future: future,
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            //snapshot.hasError
            print("category list error");
            print(snapshot.error.toString());
            return Container(
              height: 10,
            );
          } else if (snapshot.hasData) {
            //snapshot.hasData
            var categoryResponse = snapshot.data;
            return SingleChildScrollView(
              child: ListView.builder(
                itemCount: categoryResponse!.categories.length,
                scrollDirection: Axis.vertical,
                physics: NeverScrollableScrollPhysics(),
                shrinkWrap: true,
                itemBuilder: (context, index) {
                  return Padding(
                    padding: const EdgeInsets.only(
                        top: 4.0, bottom: 4.0, left: 16.0, right: 16.0),
                    child: buildCategoryItemCard(categoryResponse, index),
                  );
                },
              ),
            );
          } else {
            return SingleChildScrollView(
              child: ListView.builder(
                itemCount: 10,
                scrollDirection: Axis.vertical,
                physics: NeverScrollableScrollPhysics(),
                shrinkWrap: true,
                itemBuilder: (context, index) {
                  return Padding(
                    padding: const EdgeInsets.only(
                        top: 4.0, bottom: 4.0, left: 16.0, right: 16.0),
                    child: Row(
                      children: [
                        Shimmer.fromColors(
                          baseColor: MyTheme.shimmer_base,
                          highlightColor: MyTheme.shimmer_highlighted,
                          child: Container(
                            height: 60,
                            width: 60,
                            color: Colors.white,
                          ),
                        ),
                        Expanded(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.start,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Padding(
                                padding: const EdgeInsets.only(
                                    left: 16.0, bottom: 8.0),
                                child: Shimmer.fromColors(
                                  baseColor: MyTheme.shimmer_base,
                                  highlightColor: MyTheme.shimmer_highlighted,
                                  child: Container(
                                    height: 20,
                                    width:
                                        MediaQuery.of(context).size.width * .7,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                              Padding(
                                padding: const EdgeInsets.only(left: 16.0),
                                child: Shimmer.fromColors(
                                  baseColor: MyTheme.shimmer_base,
                                  highlightColor: MyTheme.shimmer_highlighted,
                                  child: Container(
                                    height: 20,
                                    width:
                                        MediaQuery.of(context).size.width * .5,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            );
          }
        });
  }

  Container buildCategoryItemCard(categoryResponse, index) {
    final isDark = MyTheme.isDark(context);
    final accentColor = MyTheme.teal_accent;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: MyTheme.surface(context),
        borderRadius: BorderRadius.circular(16.0),
        border: Border.all(
          color: MyTheme.border(context).withOpacity(0.5),
          width: 1.0,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDark ? 0.3 : 0.05),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16.0),
        child: Row(
            mainAxisAlignment: MainAxisAlignment.start,
            children: <Widget>[
          Container(
              width: 100,
              height: 100,
              child: Stack(
                children: [
                  Positioned.fill(
                    child: FadeInImage.assetNetwork(
                      placeholder: 'assets/placeholder.png',
                      image: PathHelper.getImageUrlSafe(
                          categoryResponse.categories[index].banner ?? ""),
                      fit: BoxFit.cover,
                    ),
                  ),
                  Positioned.fill(
                    child: Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.centerLeft,
                          end: Alignment.centerRight,
                          colors: [
                            Colors.transparent,
                            MyTheme.surface(context).withOpacity(0.2),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              )),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    categoryResponse.categories[index].name ?? "",
                    style: TextStyle(
                        color: MyTheme.primaryText(context),
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        letterSpacing: -0.3),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      _buildCategoryAction(
                        label: AppLocalizations.of(context)!
                            .category_list_screen_view_subcategories,
                        isEnabled: (categoryResponse
                                    .categories[index].number_of_children ??
                                0) >
                            0,
                        onTap: () {
                          if ((categoryResponse
                                      .categories[index].number_of_children ??
                                  0) >
                              0) {
                            Navigator.push(context,
                                MaterialPageRoute(builder: (context) {
                              return CategoryList(
                                parent_category_id:
                                    categoryResponse.categories[index].id ?? 0,
                                parent_category_name:
                                    categoryResponse.categories[index].name ?? "",
                              );
                            }));
                          } else {
                            ToastComponent.showDialog(
                                AppLocalizations.of(context)!
                                    .category_list_screen_no_subcategories,
                                context);
                          }
                        },
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 8.0),
                        child: Text(
                          "•",
                          style: TextStyle(color: MyTheme.secondaryText(context).withOpacity(0.5)),
                        ),
                      ),
                      _buildCategoryAction(
                        label: AppLocalizations.of(context)!
                            .category_list_screen_view_products,
                        isEnabled: true,
                        onTap: () {
                          Navigator.push(context,
                              MaterialPageRoute(builder: (context) {
                            return CategoryProducts(
                              category_id:
                                  categoryResponse.categories[index].id ?? 0,
                              category_name:
                                  categoryResponse.categories[index].name ?? "",
                            );
                          }));
                        },
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(right: 16.0),
            child: Icon(
              Icons.chevron_right_rounded,
              color: MyTheme.secondaryText(context).withOpacity(0.3),
            ),
          ),
        ]),
      ),
    );
  }

  Widget _buildCategoryAction({
    required String label,
    required bool isEnabled,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Text(
        label,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: isEnabled ? MyTheme.teal_accent : MyTheme.secondaryText(context).withOpacity(0.5),
        ),
      ),
    );
  }

  Container buildBottomContainer() {
    return Container(
      decoration: BoxDecoration(
        color: MyTheme.surface(context),
        border: Border(top: BorderSide(color: MyTheme.border(context))),
      ),

      height: widget.is_base_category ? 0 : 80,
      //color: Colors.white,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.only(top: 8.0),
              child: Container(
                width: (MediaQuery.of(context).size.width - 32),
                height: 40,
                child: TextButton(
                  style: TextButton.styleFrom(
                    minimumSize: Size(MediaQuery.of(context).size.width, 50),
                    backgroundColor: MyTheme.golden,
                    shape: RoundedRectangleBorder(
                        borderRadius:
                            const BorderRadius.all(Radius.circular(8.0))),
                  ),
                  child: Text(
                    AppLocalizations.of(context)!
                            .category_list_screen_all_products_of +
                        " " +
                        widget.parent_category_name,
                    style: TextStyle(
                        color: Color(0xFF344F16),
                        fontSize: 13,
                        fontWeight: FontWeight.w800),
                  ),
                  onPressed: () {
                    Navigator.push(context,
                        MaterialPageRoute(builder: (context) {
                      return CategoryProducts(
                        category_id: widget.parent_category_id,
                        category_name: widget.parent_category_name,
                      );
                    }));
                  },
                ),
              ),
            )
          ],
        ),
      ),
    );
  }
}
