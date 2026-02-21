import '../../models/container.dart';

/// Container State
///
/// Represents the state of container operations in the UI.
sealed class ContainerState {}

/// Initial state
class ContainerInitial extends ContainerState {}

/// Loading state
class ContainerLoading extends ContainerState {}

/// Loaded state with containers
class ContainerLoaded extends ContainerState {
  final List<Container> containers;

  ContainerLoaded(this.containers);
}

/// Error state
class ContainerError extends ContainerState {
  final String message;

  ContainerError(this.message);
}
