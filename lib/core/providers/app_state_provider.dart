import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pantry_pal/core/models/pantry_item.dart';
import 'package:pantry_pal/core/models/recipe.dart';
import 'package:pantry_pal/features/auth/providers/auth_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AppState {
  final int carrotCount;
  final List<Recipe> unlockedRecipes;
  final List<PantryItem> pantryItems;
  final bool isGuest;
  final bool hasSeenWelcome;
  final bool filterExpanded;
  final bool skipUnlockReminder;

  const AppState({
    required this.carrotCount,
    required this.unlockedRecipes,
    required this.pantryItems,
    required this.isGuest,
    required this.hasSeenWelcome,
    required this.filterExpanded,
    required this.skipUnlockReminder,
  });

  AppState copyWith({
    int? carrotCount,
    List<Recipe>? unlockedRecipes,
    List<PantryItem>? pantryItems,
    bool? isGuest,
    bool? hasSeenWelcome,
    bool? filterExpanded,
    bool? skipUnlockReminder,
  }) {
    return AppState(
      carrotCount: carrotCount ?? this.carrotCount,
      unlockedRecipes: unlockedRecipes ?? this.unlockedRecipes,
      pantryItems: pantryItems ?? this.pantryItems,
      isGuest: isGuest ?? this.isGuest,
      hasSeenWelcome: hasSeenWelcome ?? this.hasSeenWelcome,
      filterExpanded: filterExpanded ?? this.filterExpanded,
      skipUnlockReminder: skipUnlockReminder ?? this.skipUnlockReminder,
    );
  }
}

class AppStateNotifier extends Notifier<AppState> {
  static const _welcomeKey = 'has_seen_welcome';
  static const _filterExpandedKey = 'filter_panel_expanded';
  static const _skipUnlockReminderKey = 'skip_unlock_reminder';

  @override
  AppState build() {
    _loadPersistedFlags();

    // Sync isGuest with AuthProvider
    ref.listen(authProvider, (previous, next) {
      final isGuest = next.user?.isAnonymous ?? true;
      // Only update if changed to avoid unnecessary rebuilds
      if (state.isGuest != isGuest) {
        state = state.copyWith(isGuest: isGuest);
      }
    });

    final authState = ref.read(authProvider);
    final isGuest = authState.user?.isAnonymous ?? true;

    return AppState(
      carrotCount: 5,
      unlockedRecipes: const [],
      pantryItems: _initialPantry(),
      isGuest: isGuest,
      hasSeenWelcome: false,
      filterExpanded: true,
      skipUnlockReminder: false,
    );
  }

  Future<void> _loadPersistedFlags() async {
    final prefs = await SharedPreferences.getInstance();
    final seen = prefs.getBool(_welcomeKey) ?? false;
    final expanded = prefs.getBool(_filterExpandedKey) ?? true;
    final skipReminder = prefs.getBool(_skipUnlockReminderKey) ?? false;
    state = state.copyWith(
        hasSeenWelcome: seen,
        filterExpanded: expanded,
        skipUnlockReminder: skipReminder);
  }

  Future<void> markWelcomeSeen() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_welcomeKey, true);
    state = state.copyWith(hasSeenWelcome: true);
  }

  Future<void> setFilterExpanded(bool expanded) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_filterExpandedKey, expanded);
    state = state.copyWith(filterExpanded: expanded);
  }

  Future<void> setSkipUnlockReminder(bool skip) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_skipUnlockReminderKey, skip);
    state = state.copyWith(skipUnlockReminder: skip);
  }

  void setGuestMode(bool value) {
    state = state.copyWith(isGuest: value);
  }

  bool canSwipeRight() => !state.isGuest && state.carrotCount > 0;

  bool unlockRecipe(Recipe recipe) {
    if (!canSwipeRight()) return false;
    if (state.unlockedRecipes.any((r) => r.id == recipe.id)) {
      return true;
    }
    state = state.copyWith(
      carrotCount: state.carrotCount - 1,
      unlockedRecipes: [...state.unlockedRecipes, recipe],
    );
    return true;
  }

  void resetCarrots() {
    state = state.copyWith(carrotCount: 5);
  }

  // Pantry CRUD
  void addPantryItem(String name, int quantity) {
    final newItem = PantryItem(
      id: DateTime.now().microsecondsSinceEpoch.toString(),
      name: name,
      quantity: quantity,
    );
    state = state.copyWith(pantryItems: [...state.pantryItems, newItem]);
  }

  void editPantryItem(String id, String name, int quantity) {
    final updated = state.pantryItems.map((item) {
      if (item.id == id) {
        return item.copyWith(name: name, quantity: quantity);
      }
      return item;
    }).toList();
    state = state.copyWith(pantryItems: updated);
  }

  void deletePantryItem(String id) {
    final updated = state.pantryItems.where((item) => item.id != id).toList();
    state = state.copyWith(pantryItems: updated);
  }

  List<PantryItem> _initialPantry() {
    return const [
      PantryItem(id: 'p1', name: 'Fresh Milk', quantity: 1),
      PantryItem(id: 'p2', name: 'Cheddar Cheese', quantity: 2),
      PantryItem(id: 'p3', name: 'Tomatoes', quantity: 4),
      PantryItem(id: 'p4', name: 'Spinach', quantity: 2),
      PantryItem(id: 'p5', name: 'Eggs', quantity: 12),
      PantryItem(id: 'p6', name: 'Chicken Breast', quantity: 3),
    ];
  }
}

final appStateProvider =
    NotifierProvider<AppStateNotifier, AppState>(AppStateNotifier.new);
