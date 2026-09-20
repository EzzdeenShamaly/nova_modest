import 'dart:typed_data';

import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image_picker/image_picker.dart';
import 'package:mocktail/mocktail.dart';
import 'package:nova_modest/core/error/failure.dart';
import 'package:nova_modest/core/error/result.dart';
import 'package:nova_modest/core/media/avatar_picker.dart';
import 'package:nova_modest/features/auth/domain/entities/user.dart';
import 'package:nova_modest/features/auth/domain/repositories/auth_repository.dart';
import 'package:nova_modest/features/auth/presentation/bloc/profile_edit_bloc.dart';

class _MockAuthRepository extends Mock implements AuthRepository {}

class _MockImagePicker extends Mock implements ImagePicker {}

/// A real [AvatarPicker] over a mocked plugin: the class under test is the
/// bloc, but the picker's own "cancelled means null" contract is part of what
/// is being asserted, so it is not stubbed away.
class _FakeXFile extends Fake implements XFile {
  _FakeXFile(this._bytes);
  final Uint8List _bytes;

  @override
  Future<Uint8List> readAsBytes() async => _bytes;
}

void main() {
  late _MockAuthRepository repository;
  late _MockImagePicker plugin;
  late AvatarPicker picker;

  const saved = User(
    id: 'u1',
    email: 'sara@example.com',
    displayName: 'سارة أحمد',
    phone: '+966 55 000 1111',
  );

  /// The eight bytes that make a file a PNG, which is all the bloc's path
  /// needs — the format check itself is `image_bytes_test.dart`.
  final png = Uint8List.fromList([
    0x89,
    0x50,
    0x4e,
    0x47,
    0x0d,
    0x0a,
    0x1a,
    0x0a,
  ]);

  setUpAll(() => registerFallbackValue(Uint8List(0)));

  setUp(() {
    repository = _MockAuthRepository();
    plugin = _MockImagePicker();
    picker = AvatarPicker(plugin);
    // The test binding reports Android, so the recovery path is live in every
    // test here — which is the platform it exists for. Nothing was dropped
    // unless a test says otherwise.
    when(
      () => plugin.retrieveLostData(),
    ).thenAnswer((_) async => LostDataResponse.empty());
  });

  void given(Result<User> result) => when(
    () => repository.updateProfile(
      displayName: any(named: 'displayName'),
      phone: any(named: 'phone'),
    ),
  ).thenAnswer((_) async => result);

  group('submitting', () {
    blocTest<ProfileEditBloc, ProfileEditState>(
      'emits [Submitting, Succeeded] carrying the saved user',
      setUp: () => given(const Ok(saved)),
      build: () => ProfileEditBloc(repository, picker),
      act: (bloc) => bloc.add(
        const ProfileEditSubmitted(
          displayName: 'سارة أحمد',
          phone: '+966 55 000 1111',
        ),
      ),
      expect: () => const [
        ProfileEditSubmitting(),
        ProfileEditSucceeded(saved),
      ],
      verify: (_) => verify(
        () => repository.updateProfile(
          displayName: 'سارة أحمد',
          phone: '+966 55 000 1111',
        ),
      ).called(1),
    );

    blocTest<ProfileEditBloc, ProfileEditState>(
      'a null phone is passed through as a clear, not omitted',
      setUp: () => given(const Ok(saved)),
      build: () => ProfileEditBloc(repository, picker),
      act: (bloc) => bloc.add(const ProfileEditSubmitted(displayName: 'سارة')),
      verify: (_) => verify(
        () => repository.updateProfile(displayName: 'سارة', phone: null),
      ).called(1),
    );

    blocTest<ProfileEditBloc, ProfileEditState>(
      'emits [Submitting, Failure] when the save fails',
      setUp: () => given(const Err(NetworkFailure())),
      build: () => ProfileEditBloc(repository, picker),
      act: (bloc) => bloc.add(const ProfileEditSubmitted(displayName: 'سارة')),
      expect: () => const [
        ProfileEditSubmitting(),
        ProfileEditFailureState(NetworkFailure()),
      ],
    );

    blocTest<ProfileEditBloc, ProfileEditState>(
      'a double tap writes once',
      // Latency on purpose: droppable only drops an event while the previous
      // handler is still running, so a stub that returns instantly would let
      // both through and the test would pass for the wrong reason.
      setUp: () =>
          when(
            () => repository.updateProfile(
              displayName: any(named: 'displayName'),
              phone: any(named: 'phone'),
            ),
          ).thenAnswer((_) async {
            await Future<void>.delayed(const Duration(milliseconds: 50));
            return const Ok(saved);
          }),
      build: () => ProfileEditBloc(repository, picker),
      act: (bloc) => bloc
        ..add(const ProfileEditSubmitted(displayName: 'سارة'))
        ..add(const ProfileEditSubmitted(displayName: 'سارة')),
      wait: const Duration(milliseconds: 200),
      // droppable: without it two writes go out and their responses can resolve
      // out of order.
      verify: (_) => verify(
        () => repository.updateProfile(
          displayName: any(named: 'displayName'),
          phone: any(named: 'phone'),
        ),
      ).called(1),
    );
  });

  group('changing the picture', () {
    // `source:` is pinned rather than matched loosely: the app must ask for the
    // gallery, because it declares no camera permission and a camera source
    // would fail on a device.
    void whenPicked(Uint8List? bytes) => when(
      () => plugin.pickImage(
        source: ImageSource.gallery,
        maxWidth: any(named: 'maxWidth'),
        maxHeight: any(named: 'maxHeight'),
        imageQuality: any(named: 'imageQuality'),
      ),
    ).thenAnswer((_) async => bytes == null ? null : _FakeXFile(bytes));

    void whenUploaded(Result<User> result) => when(
      () => repository.uploadAvatar(any()),
    ).thenAnswer((_) async => result);

    blocTest<ProfileEditBloc, ProfileEditState>(
      'emits [Uploading, Updated] and hands the picked bytes to the repository',
      setUp: () {
        whenPicked(png);
        whenUploaded(const Ok(saved));
      },
      build: () => ProfileEditBloc(repository, picker),
      act: (bloc) => bloc.add(const ProfileAvatarRequested()),
      expect: () => const [
        ProfileAvatarUploading(),
        ProfileAvatarUpdated(saved),
      ],
      verify: (_) => verify(() => repository.uploadAvatar(png)).called(1),
    );

    blocTest<ProfileEditBloc, ProfileEditState>(
      'backing out of the gallery uploads nothing and reports no failure',
      setUp: () => whenPicked(null),
      build: () => ProfileEditBloc(repository, picker),
      act: (bloc) => bloc.add(const ProfileAvatarRequested()),
      // Idle, not Failure: she changed her mind, which is not an error. Without
      // the null branch this is a crash on `uploadAvatar(null)`.
      expect: () => const [ProfileEditIdle()],
      verify: (_) => verifyNever(() => repository.uploadAvatar(any())),
    );

    blocTest<ProfileEditBloc, ProfileEditState>(
      'a refused picture comes back as its own failure, not a generic one',
      setUp: () {
        whenPicked(png);
        whenUploaded(
          const Err(
            ValidationFailure(
              'Unsupported image format.',
              code: 'avatar_unsupported_format',
            ),
          ),
        );
      },
      build: () => ProfileEditBloc(repository, picker),
      act: (bloc) => bloc.add(const ProfileAvatarRequested()),
      expect: () => const [
        ProfileAvatarUploading(),
        ProfileEditFailureState(
          ValidationFailure(
            'Unsupported image format.',
            code: 'avatar_unsupported_format',
          ),
        ),
      ],
    );

    blocTest<ProfileEditBloc, ProfileEditState>(
      'a second tap while the gallery is open is dropped',
      setUp: () {
        // Latency for the same reason as the save test: droppable only drops
        // while a handler is still running.
        when(
          () => plugin.pickImage(
            source: ImageSource.gallery,
            maxWidth: any(named: 'maxWidth'),
            maxHeight: any(named: 'maxHeight'),
            imageQuality: any(named: 'imageQuality'),
          ),
        ).thenAnswer((_) async {
          await Future<void>.delayed(const Duration(milliseconds: 50));
          return _FakeXFile(png);
        });
        whenUploaded(const Ok(saved));
      },
      build: () => ProfileEditBloc(repository, picker),
      act: (bloc) => bloc
        ..add(const ProfileAvatarRequested())
        ..add(const ProfileAvatarRequested()),
      wait: const Duration(milliseconds: 200),
      verify: (_) => verify(() => repository.uploadAvatar(any())).called(1),
    );

    blocTest<ProfileEditBloc, ProfileEditState>(
      'the recovery check is silent when there is nothing to recover',
      // The common case, and on every non-Android platform the only one: it
      // must not put the screen into a loading state for nothing.
      build: () => ProfileEditBloc(repository, picker),
      act: (bloc) => bloc.add(const ProfileAvatarRecoveryRequested()),
      expect: () => const <ProfileEditState>[],
      verify: (_) => verifyNever(() => repository.uploadAvatar(any())),
    );
  });

  group('state', () {
    test('only Submitting reports itself as in flight', () {
      expect(const ProfileEditIdle().isSubmitting, isFalse);
      expect(const ProfileEditSubmitting().isSubmitting, isTrue);
      expect(const ProfileEditSucceeded(saved).isSubmitting, isFalse);
      expect(
        const ProfileEditFailureState(NetworkFailure()).isSubmitting,
        isFalse,
      );
    });

    test('Succeeded compares by user', () {
      const other = User(id: 'u1', email: 'sara@example.com', displayName: 'س');

      expect(
        const ProfileEditSucceeded(saved),
        const ProfileEditSucceeded(saved),
      );
      // Without the user in props, saving twice would emit a state equal to the
      // previous one and the listener would never fire the second time.
      expect(
        const ProfileEditSucceeded(saved),
        isNot(const ProfileEditSucceeded(other)),
      );
    });
  });
}
