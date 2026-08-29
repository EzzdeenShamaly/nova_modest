import 'package:get_it/get_it.dart';
import 'package:injectable/injectable.dart';

import 'injection.config.dart';

/// The service locator. Bindings are declared by annotation next to the class
/// they register, not listed here — this file only wires the generated setup.
final GetIt sl = GetIt.instance;

/// Called once from `main()` before `runApp`.
@InjectableInit()
Future<void> configureDependencies() async => sl.init();
