import 'package:flutter_bloc/flutter_bloc.dart';
import '../services/api_service.dart';
import 'package:dio/dio.dart';
import 'auth_cubit.dart';
import 'dart:async';

class SocialUser {
  final String id;
  final String name;
  final String steps;
  final String location;
  final int mutualFriends;
  final String initials;
  final int color1;
  final int color2;
  final bool isKing;
  final int streak;
  final String profileImage;

  SocialUser({
    required this.id,
    required this.name,
    required this.steps,
    required this.location,
    this.mutualFriends = 0,
    required this.initials,
    required this.color1,
    required this.color2,
    this.isKing = false,
    this.streak = 0,
    this.profileImage = '',
  });

  factory SocialUser.fromMap(Map<String, dynamic> map) {
    final name = map['name'] ?? 'User';
    final initials = name.split(' ').map((e) => e.isNotEmpty ? e[0] : '').take(2).join('').toUpperCase();
    
    // Generate deterministic colors based on ID
    final idHash = (map['id']?.toString() ?? '').hashCode;
    final colors = [
      [0xFFFAC775, 0xFFBA7517],
      [0xFFAFA9EC, 0xFF534AB7],
      [0xFF9FE1CB, 0xFF0F6E56],
      [0xFF85B7EB, 0xFF378ADD],
      [0xFFF0997B, 0xFFD85A30],
    ];
    final selectedColors = colors[idHash.abs() % colors.length];

    return SocialUser(
      id: map['id']?.toString() ?? '',
      name: name,
      steps: map['steps']?.toString() ?? '0',
      location: map['location']?.toString() ?? 'Unknown',
      mutualFriends: map['mutualFriends'] ?? 0,
      initials: initials.isEmpty ? '?' : initials,
      color1: selectedColors[0],
      color2: selectedColors[1],
      isKing: map['isKing'] ?? false,
      streak: map['streak'] ?? 0,
      profileImage: map['profileImage'] ?? '',
    );
  }
}

class SocialState {
  final List<SocialUser> friends;
  final List<SocialUser> incomingRequests;
  final List<SocialUser> sentRequests;
  final List<SocialUser> suggestions;
  final List<SocialUser> searchResults;
  final bool isLoading;
  final bool isSearching;
  final String? errorMessage;

  SocialState({
    this.friends = const [],
    this.incomingRequests = const [],
    this.sentRequests = const [],
    this.suggestions = const [],
    this.searchResults = const [],
    this.isLoading = false,
    this.isSearching = false,
    this.errorMessage,
  });

  SocialState copyWith({
    List<SocialUser>? friends,
    List<SocialUser>? incomingRequests,
    List<SocialUser>? sentRequests,
    List<SocialUser>? suggestions,
    List<SocialUser>? searchResults,
    bool? isLoading,
    bool? isSearching,
    String? errorMessage,
  }) {
    return SocialState(
      friends: friends ?? this.friends,
      incomingRequests: incomingRequests ?? this.incomingRequests,
      sentRequests: sentRequests ?? this.sentRequests,
      suggestions: suggestions ?? this.suggestions,
      searchResults: searchResults ?? this.searchResults,
      isLoading: isLoading ?? this.isLoading,
      isSearching: isSearching ?? this.isSearching,
      errorMessage: errorMessage,
    );
  }
}

class SocialCubit extends Cubit<SocialState> {
  final ApiService _apiService = ApiService();
  final AuthCubit _authCubit;
  StreamSubscription? _authSubscription;

  SocialCubit(this._authCubit) : super(SocialState()) {
    _authSubscription = _authCubit.stream.listen((authState) {
      if (authState.status == AuthStatus.authenticated) {
        fetchSocialData();
      }
    });
    
    if (_authCubit.state.status == AuthStatus.authenticated) {
      fetchSocialData();
    }
  }

  @override
  Future<void> close() {
    _authSubscription?.cancel();
    return super.close();
  }

  Future<void> fetchSocialData() async {
    emit(state.copyWith(isLoading: true));
    try {
      final List<SocialUser> friends = await _fetchList(() => _apiService.getFriends());
      final List<SocialUser> requests = await _fetchList(() => _apiService.getFriendRequests());
      final List<SocialUser> sent = await _fetchList(() => _apiService.getSentRequests());
      final List<SocialUser> suggestions = await _fetchList(() => _apiService.getSuggestions());

      emit(SocialState(
        friends: friends,
        incomingRequests: requests,
        sentRequests: sent,
        suggestions: suggestions,
        isLoading: false,
        isSearching: false,
        searchResults: [],
        errorMessage: null,
      ));
    } catch (e) {
      emit(state.copyWith(isLoading: false, errorMessage: 'Failed to sync social data. Check your connection.'));
    }
  }

  Future<void> searchUsers(String query) async {
    if (query.isEmpty) {
      emit(state.copyWith(isSearching: false, searchResults: []));
      return;
    }

    emit(state.copyWith(isSearching: true));
    try {
      final List<SocialUser> results = await _fetchList(() => _apiService.searchUsers(query));
      emit(state.copyWith(searchResults: results, isSearching: false, errorMessage: null));
    } catch (e) {
      emit(state.copyWith(isSearching: false, errorMessage: 'Search failed.'));
    }
  }

  void clearSearch() {
    emit(state.copyWith(isSearching: false, searchResults: []));
  }

  Future<List<SocialUser>> _fetchList(Future<Response> Function() call) async {
    try {
      final res = await call();
      if (res.data is List) {
        return (res.data as List).map((e) => SocialUser.fromMap(e as Map<String, dynamic>)).toList();
      }
    } catch (_) {
      // Silently fail and return empty list for "genuine" data if API not ready
    }
    return [];
  }

  Future<void> sendRequest(SocialUser user) async {
    try {
      await _apiService.sendFriendRequest(user.id);
      final newSuggestions = List<SocialUser>.from(state.suggestions)..removeWhere((u) => u.id == user.id);
      final newResults = List<SocialUser>.from(state.searchResults)..removeWhere((u) => u.id == user.id);
      final newSent = List<SocialUser>.from(state.sentRequests)..add(user);
      emit(state.copyWith(suggestions: newSuggestions, searchResults: newResults, sentRequests: newSent));
    } catch (e) {
      // Handle error
    }
  }

  Future<void> cancelRequest(SocialUser user) async {
    try {
      await _apiService.cancelFriendRequest(user.id);
      final newSent = List<SocialUser>.from(state.sentRequests)..removeWhere((u) => u.id == user.id);
      final newSuggestions = List<SocialUser>.from(state.suggestions)..add(user);
      emit(state.copyWith(sentRequests: newSent, suggestions: newSuggestions));
    } catch (e) {
      // Handle error
    }
  }

  Future<void> acceptRequest(SocialUser user) async {
    try {
      await _apiService.acceptFriendRequest(user.id);
      final newRequests = List<SocialUser>.from(state.incomingRequests)..removeWhere((u) => u.id == user.id);
      final newFriends = List<SocialUser>.from(state.friends)..add(user);
      emit(state.copyWith(incomingRequests: newRequests, friends: newFriends));
    } catch (e) {
      // Handle error
    }
  }

  Future<void> rejectRequest(SocialUser user) async {
    try {
      await _apiService.rejectFriendRequest(user.id);
      final newRequests = List<SocialUser>.from(state.incomingRequests)..removeWhere((u) => u.id == user.id);
      emit(state.copyWith(incomingRequests: newRequests));
    } catch (e) {
      // Handle error
    }
  }
}
