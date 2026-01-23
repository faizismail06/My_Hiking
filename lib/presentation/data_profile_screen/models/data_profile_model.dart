import 'package:equatable/equatable.dart';  

/// This class defines the variables used in the [data_profile_screen],  
/// and is typically used to hold data that is passed between different parts of the application.  
class DataProfileModel extends Equatable {  
  const DataProfileModel();  

  DataProfileModel copy() {  
    return const DataProfileModel();  
  }  

  @override  
  List<Object?> get props => [];  
}