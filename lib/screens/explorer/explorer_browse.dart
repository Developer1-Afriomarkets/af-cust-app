import 'package:flutter/material.dart';
import 'package:afriomarkets_cust_app/my_theme.dart';
import 'package:afriomarkets_cust_app/data_model/explorer_context.dart';
import 'package:afriomarkets_cust_app/repositories/explorer_repository.dart';
import 'package:afriomarkets_cust_app/ui_elements/state_square_card.dart';
import 'package:afriomarkets_cust_app/ui_elements/market_square_card.dart';
import 'package:afriomarkets_cust_app/ui_elements/store_card.dart';
import 'package:afriomarkets_cust_app/ui_elements/product_card.dart';
import 'package:shimmer/shimmer.dart';
import 'package:afriomarkets_cust_app/repositories/category_repository.dart';
import 'package:afriomarkets_cust_app/repositories/brand_repository.dart';
import 'package:afriomarkets_cust_app/data_model/category_response.dart';
import 'package:afriomarkets_cust_app/data_model/brand_response.dart';

class ExplorerBrowse extends StatefulWidget {
  final ExplorerContext explorerContext;

  const ExplorerBrowse({Key? key, required this.explorerContext}) : super(key: key);

  @override
  _ExplorerBrowseState createState() => _ExplorerBrowseState();
}

class _ExplorerBrowseState extends State<ExplorerBrowse> {
  final ExplorerRepository _repository = ExplorerRepository();
  final TextEditingController _searchController = TextEditingController();
  
  String _searchQuery = "";
  late String _selectedEntityType;
  String _selectedSort = "";

  // Filter State
  double _minPrice = 0;
  double _maxPrice = 1000000;
  String? _selectedCategoryId;
  List<String> _selectedBrands = [];
  int _activeFilterCount = 0;

  @override
  void initState() {
    super.initState();
    _selectedEntityType = _getAvailableEntityTypes().first;
  }

  void _updateFilterCount() {
    int count = 0;
    if (_selectedCategoryId != null) count++;
    if (_selectedBrands.isNotEmpty) count += _selectedBrands.length;
    if (_minPrice > 0 || _maxPrice < 1000000) count++;
    setState(() {
      _activeFilterCount = count;
    });
  }

  void _openSortSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: BoxDecoration(
          color: MyTheme.surface(context),
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("Sort Products By", 
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: MyTheme.primaryText(context))),
            const SizedBox(height: 16),
            _sortOptionTile("Default", ""),
            _sortOptionTile("Price: Low to High", "price_low_to_high"),
            _sortOptionTile("Price: High to Low", "price_high_to_low"),
            _sortOptionTile("Newest Arrivals", "newest"),
          ],
        ),
      ),
    );
  }

  Widget _sortOptionTile(String title, String value) {
    final selected = _selectedSort == value;
    return ListTile(
      onTap: () {
        setState(() => _selectedSort = value);
        Navigator.pop(context);
      },
      contentPadding: EdgeInsets.zero,
      title: Text(title, 
          style: TextStyle(
            color: selected ? MyTheme.accent_color : MyTheme.primaryText(context),
            fontWeight: selected ? FontWeight.bold : FontWeight.normal,
          )),
      trailing: selected ? Icon(Icons.check_circle, color: MyTheme.accent_color) : null,
    );
  }

  void _openAdvancedFilter() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.75,
        maxChildSize: 0.95,
        minChildSize: 0.5,
        builder: (context, controller) => StatefulBuilder(
          builder: (context, setSheetState) {
            return Container(
              decoration: BoxDecoration(
                color: MyTheme.surface(context),
                borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
              ),
              child: Column(
                children: [
                  // Header
                  Container(
                    padding: const EdgeInsets.all(20),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text("Filters", style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: MyTheme.primaryText(context))),
                        TextButton(
                          onPressed: () {
                            setSheetState(() {
                              _minPrice = 0;
                              _maxPrice = 1000000;
                              _selectedCategoryId = null;
                              _selectedBrands = [];
                            });
                          },
                          child: Text("Clear All", style: TextStyle(color: MyTheme.accent_color, fontWeight: FontWeight.bold)),
                        )
                      ],
                    ),
                  ),
                  Expanded(
                    child: ListView(
                      controller: controller,
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      children: [
                        // Price Range
                        _buildSectionHeader("Price Range"),
                        const SizedBox(height: 12),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text("₦${_minPrice.toInt()}", style: TextStyle(fontWeight: FontWeight.bold, color: MyTheme.primaryText(context))),
                            Text("₦${_maxPrice.toInt()}+", style: TextStyle(fontWeight: FontWeight.bold, color: MyTheme.primaryText(context))),
                          ],
                        ),
                        RangeSlider(
                          values: RangeValues(_minPrice, _maxPrice),
                          min: 0,
                          max: 1000000,
                          activeColor: MyTheme.accent_color,
                          inactiveColor: MyTheme.border(context),
                          onChanged: (v) {
                            setSheetState(() {
                              _minPrice = v.start;
                              _maxPrice = v.end;
                            });
                          },
                        ),
                        
                        const SizedBox(height: 24),
                        // Categories
                        _buildSectionHeader("Categories"),
                        const SizedBox(height: 12),
                        FutureBuilder<CategoryResponse>(
                          future: CategoryRepository().getFilterPageCategories(),
                          builder: (context, snapshot) {
                            if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
                            return Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              children: snapshot.data!.categories.map((cat) {
                                final isSelected = _selectedCategoryId == (cat.id ?? 0).toString();
                                return ChoiceChip(
                                  label: Text(cat.name ?? ""),
                                  selected: isSelected,
                                  onSelected: (val) {
                                    setSheetState(() {
                                      _selectedCategoryId = val ? (cat.id ?? 0).toString() : null;
                                    });
                                  },
                                  selectedColor: MyTheme.accent_color.withOpacity(0.2),
                                  labelStyle: TextStyle(color: isSelected ? MyTheme.accent_color : MyTheme.primaryText(context)),
                                );
                              }).toList(),
                            );
                          }
                        ),

                        const SizedBox(height: 24),
                        // Brands
                        _buildSectionHeader("Brands"),
                        const SizedBox(height: 12),
                        FutureBuilder<BrandResponse>(
                          future: BrandRepository().getFilterPageBrands(),
                          builder: (context, snapshot) {
                            if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
                            return Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              children: snapshot.data!.brands.map((brand) {
                                final isSelected = _selectedBrands.contains((brand.id ?? 0).toString());
                                return FilterChip(
                                  label: Text(brand.name ?? ""),
                                  selected: isSelected,
                                  onSelected: (val) {
                                    setSheetState(() {
                                      if (val) {
                                        _selectedBrands.add((brand.id ?? 0).toString());
                                      } else {
                                        _selectedBrands.remove((brand.id ?? 0).toString());
                                      }
                                    });
                                  },
                                  selectedColor: MyTheme.accent_color.withOpacity(0.2),
                                  labelStyle: TextStyle(color: isSelected ? MyTheme.accent_color : MyTheme.primaryText(context)),
                                );
                              }).toList(),
                            );
                          }
                        ),
                        const SizedBox(height: 40),
                      ],
                    ),
                  ),
                  // Apply Button
                  Container(
                    padding: const EdgeInsets.all(20),
                    child: ElevatedButton(
                      onPressed: () {
                        _updateFilterCount();
                        Navigator.pop(context);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: MyTheme.accent_color,
                        minimumSize: const Size(double.infinity, 50),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      child: const Text("Apply Filters", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                    ),
                  )
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Text(title, style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: MyTheme.primaryText(context)));
  }

  @override
  void didUpdateWidget(ExplorerBrowse oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.explorerContext != widget.explorerContext) {
      final availableTypes = _getAvailableEntityTypes();
      if (!availableTypes.contains(_selectedEntityType)) {
        setState(() {
          _selectedEntityType = availableTypes.first;
        });
      }
    }
  }

  /// Derives which entities make sense to search within the current context.
  List<String> _getAvailableEntityTypes() {
    if (widget.explorerContext.isAtStoreLevel) {
      return ["Products"];
    } else if (widget.explorerContext.isAtMarketLevel) {
      return ["Stores", "Products"];
    } else if (widget.explorerContext.isAtStateLevel) {
      return ["Markets", "Stores", "Products"]; // Stores/Products fallback to global or broader scopes if backend requires
    }
    return ["States", "Markets", "Stores", "Products"];
  }

  Widget _buildLoadingGrid() {
    return GridView.builder(
      padding: const EdgeInsets.all(16),
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 0.9,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
      ),
      itemCount: 8,
      itemBuilder: (context, index) {
        return Shimmer.fromColors(
          baseColor: MyTheme.shimmer_base,
          highlightColor: MyTheme.shimmer_highlighted,
          child: Container(
            decoration: BoxDecoration(
              color: MyTheme.surface(context),
              borderRadius: BorderRadius.circular(12.0),
            ),
          ),
        );
      },
    );
  }

  Widget _buildStateResults() {
    return FutureBuilder(
      future: _repository.getStates(query: _searchQuery),
      builder: (context, AsyncSnapshot<List<dynamic>> snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) return _buildLoadingGrid();
        if (!snapshot.hasData || snapshot.data!.isEmpty) return Center(child: Text("No states found."));
        
        return GridView.builder(
          padding: const EdgeInsets.all(16),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            childAspectRatio: 0.9,
            crossAxisSpacing: 16,
            mainAxisSpacing: 16,
          ),
          itemCount: snapshot.data!.length,
          itemBuilder: (context, index) => StateSquareCard(stateModel: snapshot.data![index]),
        );
      },
    );
  }

  Widget _buildMarketResults() {
    // If at Region level, getting all markets by query isn't directly supported by getMarketsByState
    // So if state is null, we can query all markets or show a message
    final stateId = widget.explorerContext.selectedState?.id;
    if (stateId == null) {
      return Center(child: Text("Please select a state first from Overview to search its markets."));
    }

    return FutureBuilder(
      future: _repository.getMarketsByState(stateId, query: _searchQuery),
      builder: (context, AsyncSnapshot<List<dynamic>> snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) return _buildLoadingGrid();
        if (!snapshot.hasData || snapshot.data!.isEmpty) return Center(child: Text("No markets found."));
        
        return GridView.builder(
          padding: const EdgeInsets.all(16),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            childAspectRatio: 0.9,
            crossAxisSpacing: 16,
            mainAxisSpacing: 16,
          ),
          itemCount: snapshot.data!.length,
          itemBuilder: (context, index) => MarketSquareCard(market: snapshot.data![index]),
        );
      },
    );
  }

  Widget _buildStoreResults() {
    final marketId = widget.explorerContext.selectedMarket?.id ?? 'global';
    return FutureBuilder(
      future: _repository.getStoresByMarket(marketId, query: _searchQuery),
      builder: (context, AsyncSnapshot<List<dynamic>> snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) return _buildLoadingGrid();
        if (!snapshot.hasData || snapshot.data!.isEmpty) return Center(child: Text("No stores found."));
        
        return GridView.builder(
          padding: const EdgeInsets.all(16),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            childAspectRatio: 0.7,
            crossAxisSpacing: 16,
            mainAxisSpacing: 16,
          ),
          itemCount: snapshot.data!.length,
          itemBuilder: (context, index) => StoreCard(store: snapshot.data![index]),
        );
      },
    );
  }

  Widget _buildProductResults() {
    return FutureBuilder(
      future: _repository.getProductsByContext(
        widget.explorerContext, 
        query: _searchQuery, 
        sort_key: _selectedSort,
        minPrice: _minPrice,
        maxPrice: _maxPrice,
        categoryId: _selectedCategoryId,
        brandIds: _selectedBrands,
      ),
      builder: (context, AsyncSnapshot<dynamic> snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) return _buildLoadingGrid();
        if (!snapshot.hasData || snapshot.data!.products.isEmpty) {
          return Center(child: Text("No products found."));
        }
        
        return GridView.builder(
          padding: const EdgeInsets.all(16),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            childAspectRatio: 0.65,
            crossAxisSpacing: 16,
            mainAxisSpacing: 16,
          ),
          itemCount: snapshot.data!.products.length,
          itemBuilder: (context, index) {
            final product = snapshot.data!.products[index];
            return ProductCard(
              id: product.id,
              image: product.thumbnail_image,
              name: product.name,
              main_price: product.main_price,
              stroked_price: product.stroked_price,
              has_discount: product.has_discount,
            );
          },
        );
      },
    );
  }

  String _getContextLabel() {
    if (widget.explorerContext.isAtStoreLevel) {
      return "Browsing inside ${widget.explorerContext.selectedStore?.name}";
    } else if (widget.explorerContext.isAtMarketLevel) {
      return "Browsing markets in ${widget.explorerContext.selectedMarket?.marketName}";
    } else if (widget.explorerContext.isAtStateLevel) {
      return "Browsing state of ${widget.explorerContext.selectedState?.stateName}";
    }
    return "Browsing all regions";
  }

  Widget _buildFilterOptionsBar(BuildContext context, List<String> availableTypes) {
    return Container(
      color: MyTheme.surface(context),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          // 1. Which Filter (Entity Type)
          Container(
            decoration: BoxDecoration(
                color: MyTheme.surface(context),
                border: Border.symmetric(
                    vertical: BorderSide(color: MyTheme.border(context).withOpacity(0.5), width: .5),
                    horizontal: BorderSide(color: MyTheme.border(context), width: 1))),
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            height: 36,
            width: MediaQuery.of(context).size.width * .33,
            child: DropdownButton<String>(
              isExpanded: true,
              dropdownColor: MyTheme.surface(context),
              icon: Icon(Icons.expand_more, color: MyTheme.secondaryText(context)),
              hint: Text(
                _selectedEntityType,
                style: TextStyle(color: MyTheme.primaryText(context), fontSize: 13),
              ),
              iconSize: 14,
              underline: const SizedBox(),
              value: _selectedEntityType,
              items: availableTypes.map((type) => DropdownMenuItem(
                value: type,
                child: Text(type, style: TextStyle(fontSize: 13, color: MyTheme.primaryText(context))),
              )).toList(),
              onChanged: (String? selectedType) {
                if (selectedType != null) {
                  setState(() {
                    _selectedEntityType = selectedType;
                    _searchQuery = ""; // Reset search upon category switch
                    _searchController.clear();
                    // Reset filters when switching entity type to be safe
                    _minPrice = 0;
                    _maxPrice = 1000000;
                    _selectedCategoryId = null;
                    _selectedBrands = [];
                    _activeFilterCount = 0;
                  });
                }
              },
            ),
          ),
          
          // 2. Filter Button
          GestureDetector(
            onTap: () {
              if (_selectedEntityType != "Products") {
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Advanced filtering is currently only available for products.")));
                return;
              }
              _openAdvancedFilter();
            },
            child: Container(
              decoration: BoxDecoration(
                  color: MyTheme.surface(context),
                  border: Border.symmetric(
                      vertical: BorderSide(color: MyTheme.border(context).withOpacity(0.5), width: .5),
                      horizontal: BorderSide(color: MyTheme.border(context), width: 1))),
              height: 36,
              width: MediaQuery.of(context).size.width * .33,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.filter_alt_outlined, size: 13, color: _activeFilterCount > 0 ? MyTheme.accent_color : MyTheme.primaryText(context)),
                      const SizedBox(width: 4),
                      Text(
                        "Filter",
                        style: TextStyle(
                          color: _activeFilterCount > 0 ? MyTheme.accent_color : MyTheme.primaryText(context), 
                          fontSize: 13,
                          fontWeight: _activeFilterCount > 0 ? FontWeight.bold : FontWeight.normal
                        ),
                      ),
                    ],
                  ),
                  if (_activeFilterCount > 0)
                    Positioned(
                      right: 12,
                      top: 4,
                      child: Container(
                        padding: const EdgeInsets.all(2),
                        decoration: BoxDecoration(color: MyTheme.golden, shape: BoxShape.circle),
                        constraints: const BoxConstraints(minWidth: 14, minHeight: 14),
                        child: Text(
                          "$_activeFilterCount",
                          style: const TextStyle(color: Colors.black, fontSize: 8, fontWeight: FontWeight.bold),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
          
          // 3. Sort Button
          GestureDetector(
            onTap: () {
              if (_selectedEntityType != "Products") {
                 ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Sorting is currently only available for products.")));
                 return;
              }
              _openSortSheet();
            },
            child: Container(
              decoration: BoxDecoration(
                  color: MyTheme.surface(context),
                  border: Border.symmetric(
                      vertical: BorderSide(color: MyTheme.border(context).withOpacity(0.5), width: .5),
                      horizontal: BorderSide(color: MyTheme.border(context), width: 1))),
              height: 36,
              width: MediaQuery.of(context).size.width * .33,
              child: Center(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.swap_vert, size: 13, color: _selectedSort.isNotEmpty ? MyTheme.accent_color : MyTheme.primaryText(context)),
                      const SizedBox(width: 4),
                      Text(
                        "Sort",
                        style: TextStyle(
                          color: _selectedSort.isNotEmpty ? MyTheme.accent_color : MyTheme.primaryText(context), 
                          fontSize: 13,
                          fontWeight: _selectedSort.isNotEmpty ? FontWeight.bold : FontWeight.normal
                        ),
                      ),
                    ],
                  ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final availableTypes = _getAvailableEntityTypes();

    return Column(
      children: [
        // Context Banner
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(12),
          color: MyTheme.accent_color.withOpacity(0.1),
          child: Row(
            children: [
              Icon(Icons.location_on, size: 16, color: MyTheme.accent_color),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  _getContextLabel(),
                  style: TextStyle(
                    color: MyTheme.accent_color,
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                  ),
                ),
              ),
            ],
          ),
        ),
        
        // Search Bar
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
          child: TextField(
            controller: _searchController,
            onSubmitted: (value) {
              setState(() {
                _searchQuery = value;
              });
            },
            style: TextStyle(color: MyTheme.primaryText(context)),
            decoration: InputDecoration(
              hintText: "Search $_selectedEntityType...",
              hintStyle: TextStyle(color: MyTheme.secondaryText(context).withOpacity(0.6)),
              prefixIcon: Icon(Icons.search, color: MyTheme.secondaryText(context)),
              filled: true,
              fillColor: MyTheme.surface(context).withOpacity(0.6),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: MyTheme.border(context)),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: MyTheme.border(context)),
              ),
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 0),
            ),
          ),
        ),

        // Native Filter Appbar Replica
        _buildFilterOptionsBar(context, availableTypes),

        // Results Area
        const SizedBox(height: 8),
        Expanded(
          child: Builder(builder: (context) {
            switch (_selectedEntityType) {
              case "States":
                return _buildStateResults();
              case "Markets":
                return _buildMarketResults();
              case "Stores":
                return _buildStoreResults();
              case "Products":
                return _buildProductResults();
              default:
                return const SizedBox.shrink();
            }
          }),
        ),
      ],
    );
  }
}
