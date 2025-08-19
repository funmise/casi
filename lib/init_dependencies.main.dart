part of 'init_dependencies.dart';

final serviceLocator = GetIt.instance;

Future<void> initDependencies() async {
  // --- external SDK initialization ---
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  await GoogleSignIn.instance.initialize();

  // Firebase and google singletons
  serviceLocator
    ..registerLazySingleton<fa.FirebaseAuth>(() => fa.FirebaseAuth.instance)
    ..registerLazySingleton<FirebaseFirestore>(() => FirebaseFirestore.instance)
    ..registerLazySingleton<GoogleSignIn>(() => GoogleSignIn.instance);

  // ---- Core ----
  // app-user: remote data source + repo + usecase + cubit
  serviceLocator.registerLazySingleton<UserRemoteDataSource>(
    () => UserRemoteDataSourceImpl(
      auth: serviceLocator<fa.FirebaseAuth>(),
      db: serviceLocator<FirebaseFirestore>(),
    ),
  );

  serviceLocator.registerLazySingleton<UserRepository>(
    () => UserRepositoryImpl(serviceLocator<UserRemoteDataSource>()),
  );

  serviceLocator.registerLazySingleton<WatchUser>(
    () => WatchUser(serviceLocator<UserRepository>()),
  );

  serviceLocator.registerFactory<UserCubit>(
    () => UserCubit(watch: serviceLocator(), signOut: serviceLocator()),
  );

  // ---- Auth ----
  serviceLocator
    // DataSource
    ..registerFactory<AuthRemoteDataSource>(
      () => AuthRemoteDataSourceImpl(
        auth: serviceLocator(),
        google: serviceLocator(),
      ),
    )
    //Repository
    ..registerFactory<AuthRepository>(
      () => AuthRepositoryImpl(serviceLocator()),
    )
    //UseCases
    ..registerFactory(() => GoogleSignInUC(serviceLocator()))
    ..registerFactory(() => GetCurrentUser(serviceLocator()))
    ..registerFactory<IsSignOut>(() => SignOut(serviceLocator()))
    //Blocs
    ..registerLazySingleton(
      () => AuthBloc(
        googleSignIn: serviceLocator(),
        getCurrentUser: serviceLocator(),
        signOut: serviceLocator(),
        watchUser: serviceLocator(),
      ),
    );

  // ---- Enrollment ----
  serviceLocator
    // DataSource
    ..registerFactory<EnrollmentRemoteDataSource>(
      () => EnrollmentRemoteDataSourceImpl(serviceLocator()),
    )
    //Repository
    ..registerFactory<EnrollmentRepository>(
      () => EnrollmentRepositoryImpl(serviceLocator()),
    )
    //UseCases
    ..registerFactory(() => QueryClinicsPrefix(serviceLocator()))
    ..registerFactory(() => CreatePendingClinic(serviceLocator()))
    ..registerFactory(() => SetEnrollmentClinic(serviceLocator()))
    ..registerFactory(() => GetEnrollment(serviceLocator()))
    ..registerFactory(() => GetActiveEthics(serviceLocator()))
    ..registerFactory(() => AcceptEthics(serviceLocator()))
    //Blocs
    ..registerFactory(
      () => EnrollmentBloc(
        queryClinics: serviceLocator(),
        createClinic: serviceLocator(),
        setClinic: serviceLocator(),
        getEnrollment: serviceLocator(),
        getActiveEthics: serviceLocator(),
        acceptEthics: serviceLocator(),
      ),
    );
}
