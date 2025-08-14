part of 'init_dependencies.dart';

final serviceLocator = GetIt.instance;
const _webClientId =
    "171669602068-2ggkl854la6ilk8u86d9brh6qicqvv1f.apps.googleusercontent.com";

Future<void> initDependencies() async {
  // --- SDK bootstrapping ---
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  await GoogleSignIn.instance.initialize(serverClientId: _webClientId);

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
