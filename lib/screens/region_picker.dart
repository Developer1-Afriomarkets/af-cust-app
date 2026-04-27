import 'package:flutter/material.dart';
import 'package:afriomarkets_cust_app/my_theme.dart';
import 'package:afriomarkets_cust_app/services/region_service.dart';
import 'package:afriomarkets_cust_app/helpers/price_helper.dart';

/// Region/currency picker screen.
/// Lists all Medusa regions with their currencies and country flags.
class RegionPicker extends StatefulWidget {
  const RegionPicker({Key? key}) : super(key: key);

  @override
  _RegionPickerState createState() => _RegionPickerState();
}

class _RegionPickerState extends State<RegionPicker> {
  List<MedusaRegion> _regions = [];
  MedusaRegion? _selectedRegion;
  bool _isLoading = true;

  // Country flag emoji from ISO-2 code
  static String _flagEmoji(String countryCode) {
    if (countryCode.length != 2) return '🌍';
    final int firstChar =
        countryCode.toUpperCase().codeUnitAt(0) - 0x41 + 0x1F1E6;
    final int secondChar =
        countryCode.toUpperCase().codeUnitAt(1) - 0x41 + 0x1F1E6;
    return String.fromCharCode(firstChar) + String.fromCharCode(secondChar);
  }

  // Accent colors for region cards (from web's African palette)
  static const List<Color> _cardColors = [
    Color(0xFF048630), // green
    Color(0xFF861B04), // deep red
    Color(0xFF043086), // blue
    Color(0xFF04865F), // teal
    Color(0xFF866204), // amber
    Color(0xFF3D8B7A), // brand teal
  ];

  @override
  void initState() {
    super.initState();
    _loadRegions();
  }

  Future<void> _loadRegions() async {
    final regions = await RegionService.fetchRegions();
    final current = await RegionService.getCurrentRegion();
    if (mounted) {
      setState(() {
        _regions = regions;
        _selectedRegion = current;
        _isLoading = false;
      });
    }
  }

  Future<void> _selectRegion(MedusaRegion region) async {
    final countryCode =
        region.countries.isNotEmpty ? region.countries.first.iso2 : 'ng';
    await RegionService.setRegion(region, countryCode);
    if (mounted) {
      setState(() {
        _selectedRegion = region;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Region set to ${region.name} (${PriceHelper.getSymbol(region.currencyCode)})',
            style: const TextStyle(color: Colors.white),
          ),
          backgroundColor: MyTheme.accent_color,
          duration: const Duration(seconds: 2),
        ),
      );
      Navigator.of(context).pop(region);
    }
  }  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: MyTheme.primaryText(context)),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Select Region',
              style: TextStyle(
                color: MyTheme.primaryText(context),
                fontSize: 18,
                fontWeight: FontWeight.w700,
              ),
            ),
            Text(
              'Choose your shopping region & currency',
              style: TextStyle(
                color: MyTheme.secondaryText(context),
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
      body: MyTheme.brandBackground(
        context: context,
        child: buildBody(context),
      ),
    );
  }

  Widget buildBody(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_regions.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.public_off,
                size: 64, color: MyTheme.secondaryText(context)),
            const SizedBox(height: 16),
            Text(
              'No regions available',
              style: TextStyle(
                color: MyTheme.primaryText(context),
                fontSize: 16,
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _regions.length,
      itemBuilder: (context, index) {
        final region = _regions[index];
        final isSelected = _selectedRegion?.id == region.id;
        final cardColor = _cardColors[index % _cardColors.length];

        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12.0),
              boxShadow: [
                BoxShadow(
                  color: isSelected
                      ? cardColor.withOpacity(0.4)
                      : Colors.black.withOpacity(0.05),
                  blurRadius: 16,
                  spreadRadius: 1,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                borderRadius: BorderRadius.circular(12.0),
                onTap: () => _selectRegion(region),
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12.0),
                    gradient: isSelected
                        ? LinearGradient(
                            colors: [
                              cardColor,
                              cardColor.withOpacity(0.85),
                            ],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          )
                        : null,
                    color: isSelected ? null : MyTheme.surface(context),
                    border: Border.all(
                      color: isSelected
                          ? Colors.white.withOpacity(0.3)
                          : MyTheme.border(context),
                      width: isSelected ? 2 : 1,
                    ),
                  ),
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      Container(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          color: isSelected
                              ? Colors.white.withOpacity(0.2)
                              : cardColor.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Center(
                          child: Text(
                            region.countries.isNotEmpty
                                ? _flagEmoji(region.countries.first.iso2)
                                : '🌍',
                            style: const TextStyle(fontSize: 24),
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              region.name,
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: isSelected
                                    ? Colors.white
                                    : MyTheme.primaryText(context),
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '${PriceHelper.getSymbol(region.currencyCode)} ${region.currencyCode}',
                              style: TextStyle(
                                fontSize: 14,
                                color: isSelected
                                    ? Colors.white70
                                    : MyTheme.secondaryText(context),
                              ),
                            ),
                            if (region.countries.isNotEmpty)
                              Padding(
                                padding: const EdgeInsets.only(top: 4),
                                child: Text(
                                  region.countries
                                          .map((c) => c.displayName)
                                          .take(3)
                                          .join(', ') +
                                      (region.countries.length > 3
                                          ? '...'
                                          : ''),
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: isSelected
                                        ? Colors.white54
                                        : MyTheme.secondaryText(context)
                                            .withOpacity(0.7),
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                          ],
                        ),
                      ),
                      if (isSelected)
                        Container(
                          width: 28,
                          height: 28,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.1),
                                blurRadius: 4,
                              )
                            ],
                          ),
                          child: Icon(
                            Icons.check,
                            color: cardColor,
                            size: 18,
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
