import 'package:equatable/equatable.dart';  
import '../../../core/app_export.dart';  
import '../models/app_navigation_model.dart';  
part 'app_navigation_event.dart';  
part 'app_navigation_state.dart';  

/// A bloc that manages the state of AppNavigation based on dispatched events.  
class AppNavigationBloc extends Bloc<AppNavigationEvent, AppNavigationState> {  
  AppNavigationBloc(super.initialState) {  
    on<AppNavigationInitialEvent>(_onInitialize);  
  }  

  _onInitialize(  
    AppNavigationInitialEvent event,  
    Emitter<AppNavigationState> emit,  
  ) async {  
    // Initialization logic goes here  
  }  
}