part of 'theme_bloc.dart';

class ThemeState extends Equatable {
  final String themeType;

  const ThemeState({required this.themeType});

  @override
  List<Object?> get props => [themeType];

  ThemeState copyWith({String? themeType}) {
    return ThemeState(themeType: themeType ?? this.themeType);
  }
}
