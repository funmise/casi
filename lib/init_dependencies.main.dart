part of 'init_dependencies.dart';

final serviceLocator = GetIt.instance;
final _fln = FlutterLocalNotificationsPlugin();

Future<void> initDependencies() async {
  // FCM background handler
  FirebaseMessaging.onBackgroundMessage(_bgHandler);

  // --- external SDK initialization ---
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  await GoogleSignIn.instance.initialize();

  // Ensure FCM auto-init + permissions
  await FirebaseMessaging.instance.setAutoInitEnabled(true);
  await FirebaseMessaging.instance.requestPermission();

  // Local notifications init
  const androidInit = AndroidInitializationSettings('@mipmap/ic_launcher');
  const iosInit = DarwinInitializationSettings();
  await _fln.initialize(
    const InitializationSettings(android: androidInit, iOS: iosInit),
  );

  // iOS: allow showing notification while app is foreground
  await FirebaseMessaging.instance.setForegroundNotificationPresentationOptions(
    alert: true,
    badge: true,
    sound: true,
  );

  // Foreground handler -> show a local notification
  FirebaseMessaging.onMessage.listen((RemoteMessage m) async {
    final n = m.notification;
    if (n == null) return; // if we send data-only, render from m.data

    const androidDetails = AndroidNotificationDetails(
      'casi_general', // must match our created channel id
      'CASI',
      importance: Importance.high,
      priority: Priority.high,
    );
    const iosDetails = DarwinNotificationDetails();

    await _fln.show(
      n.hashCode,
      n.title,
      n.body,
      const NotificationDetails(android: androidDetails, iOS: iosDetails),
      payload: m.data.isEmpty ? null : m.data.toString(),
    );
  });

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
    () => UserCubit(
      watch: serviceLocator(),
      signOut: serviceLocator(),
      deleteAccount: serviceLocator(),
    ),
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
    ..registerFactory<IsSignOut>(() => SignOut(serviceLocator()))
    ..registerFactory<IsDeleteAccount>(() => DeleteAccount(serviceLocator()))
    //Blocs
    ..registerFactory(
      () => AuthBloc(
        googleSignIn: serviceLocator(),
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

  // ---- Survey ----
  // data sources
  serviceLocator.registerLazySingleton<SurveyRemoteDataSource>(
    () => SurveyRemoteDataSourceImpl(serviceLocator()),
  );

  // repository
  serviceLocator.registerLazySingleton<SurveyRepository>(
    () => SurveyRepositoryImpl(serviceLocator()),
  );

  // use cases
  serviceLocator.registerFactory(() => GetActiveSurvey(serviceLocator()));
  serviceLocator.registerFactory(() => GetUserSubmission(serviceLocator()));
  serviceLocator.registerFactory(() => SaveSurveyDraft(serviceLocator()));
  serviceLocator.registerFactory(() => SubmitSurvey(serviceLocator()));

  // bloc
  serviceLocator.registerFactory(
    () => SurveyBloc(
      getActive: serviceLocator(),
      getUserSubmission: serviceLocator(),
      saveDraft: serviceLocator(),
      submitSurvey: serviceLocator(),
    ),
  );
}

@pragma('vm:entry-point')
Future<void> _bgHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
}
