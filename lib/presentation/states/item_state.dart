import '../../models/item.dart';

/// Item State
///
/// Represents the state of item operations in the UI.
sealed class ItemState {}

/// Initial state
class ItemInitial extends ItemState {}

/// Loading state
class ItemLoading extends ItemState {}

/// Loaded state with items
class ItemLoaded extends ItemState {
  final List<Item> items;

  ItemLoaded(this.items);
}

/// Error state
class ItemError extends ItemState {
  final String message;

  ItemError(this.message);
}
