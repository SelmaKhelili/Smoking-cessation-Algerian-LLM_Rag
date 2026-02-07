part of 'home_cubit.dart';

enum HomeStatus { initial, loading, success, failure }

class HomeState extends Equatable {
  final HomeStatus status;
  final DateTime currentDate;
  final String dailyQuote;
  // New stats fields
  final int quitDays;
  final int cigarettesAvoided;
  final int moneySaved;
  final Map<String, String> moodData; // date -> mood mapping

  const HomeState({
    this.status = HomeStatus.initial,
    required this.currentDate,
    this.dailyQuote = '"The secret to getting ahead is getting started."',
    this.quitDays = 0,
    this.cigarettesAvoided = 0,
    this.moneySaved = 0,
    this.moodData = const {},
  });

  factory HomeState.initial() {
    return HomeState(
      currentDate: DateTime.now(),
      moodData: const {},
    );
  }

  HomeState copyWith({
    HomeStatus? status,
    DateTime? currentDate,
    String? dailyQuote,
    int? quitDays,
    int? cigarettesAvoided,
    int? moneySaved,
    Map<String, String>? moodData,
  }) {
    return HomeState(
      status: status ?? this.status,
      currentDate: currentDate ?? this.currentDate,
      dailyQuote: dailyQuote ?? this.dailyQuote,
      quitDays: quitDays ?? this.quitDays,
      cigarettesAvoided: cigarettesAvoided ?? this.cigarettesAvoided,
      moneySaved: moneySaved ?? this.moneySaved,
      moodData: moodData ?? this.moodData,
    );
  }

  @override
  List<Object?> get props => [
        status,
        currentDate,
        dailyQuote,
        quitDays,
        cigarettesAvoided,
        moneySaved,
        moodData,
      ];
}
