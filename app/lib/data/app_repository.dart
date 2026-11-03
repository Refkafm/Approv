import 'family_repository.dart';
import 'reward_repository.dart';
import 'settings_models.dart';
import 'submission_repository.dart';
import 'task_repository.dart';
import 'wallet_repository.dart';

/// Semua akses data app. Implementasi: SupabaseRepository (produksi) dan FakeRepository (tes & demo).
abstract interface class AppRepository
    implements
        FamilyRepository,
        TaskRepository,
        SubmissionRepository,
        WalletRepository,
        RewardRepository,
        SettingsRepository {}
