# Architecture Documentation

This project follows a **Clean Architecture** pattern with **Riverpod** for state management.

## Architecture Layers

### 1. **Domain Layer** (`lib/models/`)
- **Models**: Core business entities (Container, Item, AppSettings)
- Pure Dart classes with no dependencies on external frameworks
- Located in `lib/models/` directory

### 2. **Data Layer** (`lib/data/`)
- **Data Sources** (`datasources/`): Direct interaction with storage (Hive)
  - `LocalStorageDataSource`: Abstract interface
  - `HiveLocalStorageDataSource`: Hive implementation
  
- **Repositories** (`repositories/`): Clean API for data operations
  - `ContainerRepository`: Container data operations
  - `ItemRepository`: Item data operations
  - `SettingsRepository`: Settings data operations

### 3. **Application Layer** (`lib/application/`)
- **Services** (`services/`): Business logic orchestration
  - `ContainerApplicationService`: Container business logic
  - `ItemApplicationService`: Item business logic
  - `SettingsApplicationService`: Settings business logic

### 4. **Presentation Layer** (`lib/presentation/`)
- **States** (`states/`): UI state definitions
  - `ContainerState`: Container UI states
  - `ItemState`: Item UI states
  - `SettingsState`: Settings UI states

- **Controllers** (`controllers/`): StateNotifiers managing UI state
  - `ContainerController`: Manages container state and operations
  - `ItemController`: Manages item state and operations
  - `SettingsController`: Manages settings state and operations

- **Providers** (`providers/`): Riverpod providers
  - `data_providers.dart`: Data source and repository providers
  - `service_providers.dart`: Application service providers
  - `initialization_provider.dart`: App initialization logic

## Data Flow

```
Widgets → Controllers (StateNotifiers) → Services → Repositories → Data Sources
```

1. **Widgets** consume state from Controllers via Riverpod providers
2. **Controllers** handle user actions and call Services
3. **Services** orchestrate business logic using Repositories
4. **Repositories** abstract data access using Data Sources
5. **Data Sources** interact with actual storage (Hive)

## Usage Examples

### Using Container Controller in a Widget

```dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'presentation/controllers/container_controller.dart';

class ContainerListWidget extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final containerState = ref.watch(containerControllerProvider);
    
    return switch (containerState) {
      ContainerLoading() => CircularProgressIndicator(),
      ContainerLoaded(containers: final containers) => 
        ListView.builder(
          itemCount: containers.length,
          itemBuilder: (context, index) => 
            ContainerCard(container: containers[index]),
        ),
      ContainerError(message: final message) => 
        Text('Error: $message'),
      _ => SizedBox(),
    };
  }
}
```

### Creating a Container

```dart
final controller = ref.read(containerControllerProvider.notifier);
final success = await controller.createContainer(
  Container.create(
    name: 'My Container',
    type: ContainerType.box,
  ),
);
```

### Using Settings

```dart
final settingsAsync = ref.watch(settingsProvider);

settingsAsync.when(
  data: (settings) => Text('Theme: ${settings.themeMode}'),
  loading: () => CircularProgressIndicator(),
  error: (err, stack) => Text('Error: $err'),
);
```

## Provider Structure

### Data Layer Providers
- `localStorageDataSourceProvider`: Provides Hive data source
- `containerRepositoryProvider`: Provides container repository
- `itemRepositoryProvider`: Provides item repository
- `settingsRepositoryProvider`: Provides settings repository

### Application Layer Providers
- `containerServiceProvider`: Provides container application service
- `itemServiceProvider`: Provides item application service
- `settingsServiceProvider`: Provides settings application service

### Presentation Layer Providers
- `containerControllerProvider`: Container state notifier
- `itemControllerProvider`: Item state notifier
- `settingsControllerProvider`: Settings state notifier
- `settingsProvider`: Async settings provider
- `initializationProvider`: App initialization provider

## Migration Notes

The architecture maintains backward compatibility with existing code:
- Old services in `lib/services/` still work
- Models in `lib/models/` are re-exported from `lib/domain/models/`
- Gradually migrate screens to use new Riverpod controllers

## Benefits

1. **Separation of Concerns**: Clear boundaries between layers
2. **Testability**: Easy to mock repositories and services
3. **Maintainability**: Changes in one layer don't affect others
4. **Scalability**: Easy to add new features following the same pattern
5. **Type Safety**: Riverpod provides compile-time type checking
6. **Reactive**: Automatic UI updates when state changes
