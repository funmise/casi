part of 'init_dependencies.dart';

final serviceLocator = GetIt.instance;

Future<void> initDependencies() async {
  // --- SDK bootstrapping ---
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  // google_sign_in v7: must initialize exactly once
  await GoogleSignIn.instance.initialize();

  // Firebase singletons
  serviceLocator
    ..registerLazySingleton<fa.FirebaseAuth>(() => fa.FirebaseAuth.instance)
    ..registerLazySingleton<GoogleSignIn>(() => GoogleSignIn.instance);

  // Core
  serviceLocator.registerLazySingleton(() => AppUserCubit());

  // Auth
  serviceLocator
    ..registerFactory<AuthRemoteDataSource>(
      () => AuthRemoteDataSourceImpl(
        auth: serviceLocator(),
        google: serviceLocator(),
      ),
    )
    ..registerFactory<AuthRepository>(
      () => AuthRepositoryImpl(serviceLocator()),
    )
    ..registerFactory(() => GoogleSignInUC(serviceLocator()))
    ..registerFactory(() => GetCurrentUser(serviceLocator()))
    ..registerFactory(() => SignOut(serviceLocator()))
    ..registerLazySingleton(
      () => AuthBloc(
        googleSignIn: serviceLocator(),
        getCurrentUser: serviceLocator(),
        signOut: serviceLocator(),
      ),
    );
}
