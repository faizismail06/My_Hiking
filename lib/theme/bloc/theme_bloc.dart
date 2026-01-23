import 'package:equatable/equatable.dart';
import '../../core/app_export.dart';

part 'theme_event.dart';
part 'theme_state.dart';

class ThemeBloc extends Bloc<ThemeEvent, ThemeState> {
  ThemeBloc(super.initialState) {
    on<ThemeChangeEvent>(_changeTheme);
  }

  void _changeTheme(
    ThemeChangeEvent event,
    Emitter<ThemeState> emit,
  ) async {
    emit(state.copyWith(themeType: event.themeType));
  }
}
