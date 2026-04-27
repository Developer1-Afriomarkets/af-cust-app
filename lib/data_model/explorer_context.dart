import 'package:afriomarkets_cust_app/data_model/state_model.dart';
import 'package:afriomarkets_cust_app/data_model/market_model.dart';
import 'package:afriomarkets_cust_app/data_model/shop_response.dart'; // Using the existing shop model for stores

class ExplorerContext {
  final StateModel? selectedState;
  final MarketModel? selectedMarket;
  final Shop? selectedStore;

  ExplorerContext({
    this.selectedState,
    this.selectedMarket,
    this.selectedStore,
  });

  /// True if we are at the top 'Region/Country' level looking at states
  bool get isAtRegionLevel => selectedState == null && selectedMarket == null && selectedStore == null;
  
  /// True if we have selected a State and are looking at Markets
  bool get isAtStateLevel => selectedState != null && selectedMarket == null && selectedStore == null;
  
  /// True if we have selected a Market and are looking at Stores
  bool get isAtMarketLevel => selectedState != null && selectedMarket != null && selectedStore == null;

  /// True if we have reached the lowest Store level
  bool get isAtStoreLevel => selectedState != null && selectedMarket != null && selectedStore != null;

  /// Create a new context by drilling down into a state
  ExplorerContext withState(StateModel state) {
    return ExplorerContext(selectedState: state);
  }

  /// Create a new context by drilling down into a market
  ExplorerContext withMarket(MarketModel market) {
    return ExplorerContext(
      selectedState: selectedState,
      selectedMarket: market,
    );
  }

  /// Create a new context by drilling down into a store
  ExplorerContext withStore(Shop store) {
    return ExplorerContext(
      selectedState: selectedState,
      selectedMarket: selectedMarket,
      selectedStore: store,
    );
  }

  /// Go back up one level
  ExplorerContext pop() {
    if (isAtStoreLevel) {
      return ExplorerContext(selectedState: selectedState, selectedMarket: selectedMarket);
    } else if (isAtMarketLevel) {
      return ExplorerContext(selectedState: selectedState);
    }
    return ExplorerContext(); // Back to region level
  }
}
