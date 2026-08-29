part of 'search_bloc.dart';

sealed class SearchEvent extends Equatable {
  const SearchEvent();

  @override
  List<Object?> get props => const [];
}

/// The screen opened and needs its discovery content: recent searches, the
/// trending terms and the categories to browse.
final class SearchOpened extends SearchEvent {
  const SearchOpened();
}

/// A keystroke.
///
/// Debounced, so a fast typist produces one search rather than one per letter,
/// and **not** recorded in history — otherwise the recent list fills with every
/// prefix of what was actually searched for.
final class SearchQueryChanged extends SearchEvent {
  const SearchQueryChanged(this.query);

  final String query;

  @override
  List<Object?> get props => [query];
}

/// The query was committed: the keyboard's search action, or a tap on a recent
/// or trending chip. Runs immediately and **is** recorded.
final class SearchSubmitted extends SearchEvent {
  const SearchSubmitted(this.query);

  final String query;

  @override
  List<Object?> get props => [query];
}

/// The field was emptied, returning to the discovery screen.
final class SearchCleared extends SearchEvent {
  const SearchCleared();
}

/// The shared filter sheet was applied.
final class SearchFilterChanged extends SearchEvent {
  const SearchFilterChanged(this.filter);

  final ProductFilter filter;

  @override
  List<Object?> get props => [filter];
}

/// A different ordering was chosen.
final class SearchSortChanged extends SearchEvent {
  const SearchSortChanged(this.sort);

  final ProductSort sort;

  @override
  List<Object?> get props => [sort];
}

/// The × on one recent-search chip.
final class SearchHistoryEntryRemoved extends SearchEvent {
  const SearchHistoryEntryRemoved(this.term);

  final String term;

  @override
  List<Object?> get props => [term];
}

/// "Clear all" above the recent searches.
final class SearchHistoryCleared extends SearchEvent {
  const SearchHistoryCleared();
}
