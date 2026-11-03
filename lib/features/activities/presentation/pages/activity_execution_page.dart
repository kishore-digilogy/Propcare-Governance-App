import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/theme/app_theme.dart';
import '../../data/datasources/activities_remote_datasource.dart';
import '../bloc/activities_bloc.dart';
import '../bloc/activities_event.dart';
import '../bloc/activities_state.dart';
import '../widgets/activity_execution_view.dart';

/// Standalone page that loads and presents an activity in the full Execution View.
/// Supports visit submission, draft saving, and MOM sending.
class ActivityExecutionPage extends StatefulWidget {
  final String activityId;
  final String? siteName;
  final ActivitiesBloc? bloc;

  const ActivityExecutionPage({
    super.key,
    required this.activityId,
    this.siteName,
    this.bloc,
  });

  @override
  State<ActivityExecutionPage> createState() => _ActivityExecutionPageState();
}

class _ActivityExecutionPageState extends State<ActivityExecutionPage> {
  late final ActivitiesBloc _bloc;
  late final bool _ownsBloc;

  @override
  void initState() {
    super.initState();
    if (widget.bloc != null) {
      _bloc = widget.bloc!;
      _ownsBloc = false;
    } else {
      _bloc = ActivitiesBloc(
        remoteDataSource: ActivitiesRemoteDataSourceImpl(),
      );
      _ownsBloc = true;
    }
    _bloc.add(SelectActivityForDetail(widget.activityId));
  }

  @override
  void dispose() {
    if (_ownsBloc) {
      _bloc.close();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider.value(
      value: _bloc,
      child: Scaffold(
        backgroundColor: const Color(0xFFF8FAFC),
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.only(top: 10),
            child: BlocConsumer<ActivitiesBloc, ActivitiesState>(
              listener: (context, state) {
                if (state is ActivitiesLoaded) {
                  if (state.actionSuccessMessage != null) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(state.actionSuccessMessage!),
                        backgroundColor: const Color(0xFF16A34A),
                        behavior: SnackBarBehavior.floating,
                      ),
                    );
                  } else if (state.actionErrorMessage != null && state.selectedActivityDetail != null) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(state.actionErrorMessage!),
                        backgroundColor: const Color(0xFFDC2626),
                        behavior: SnackBarBehavior.floating,
                      ),
                    );
                  }
                }
              },
              builder: (context, state) {
                if (state is ActivitiesLoaded) {
                  if (state.isLoadingActivity) {
                    return const Center(
                      child: CircularProgressIndicator(color: AppColors.primary),
                    );
                  }

                  if (state.selectedActivityDetail != null) {
                    return ActivityExecutionView(
                      activityDetail: state.selectedActivityDetail!,
                      isSubmittingVisit: state.isSubmittingVisit,
                      isSendingMom: state.isSendingMom,
                      bloc: _bloc,
                      onBack: () => Navigator.of(context).pop(true),
                    );
                  }

                  if (state.actionErrorMessage != null) {
                    return _buildErrorView(state.actionErrorMessage!);
                  }
                }

                if (state is ActivitiesLoading || state is ActivitiesInitial) {
                  return const Center(
                    child: CircularProgressIndicator(color: AppColors.primary),
                  );
                }

                if (state is ActivitiesError) {
                  return _buildErrorView(state.message);
                }

                return const SizedBox.shrink();
              },
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildErrorView(String message) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline_rounded, size: 48, color: Color(0xFFDC2626)),
            const SizedBox(height: 12),
            Text(
              'Failed to load activity',
              style: GoogleFonts.outfit(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: const Color(0xFF1E293B),
              ),
            ),
            const SizedBox(height: 6),
            Text(
              message,
              textAlign: TextAlign.center,
              style: GoogleFonts.outfit(fontSize: 13, color: const Color(0xFF64748B)),
            ),
            const SizedBox(height: 20),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                OutlinedButton(
                  onPressed: () => Navigator.of(context).pop(),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: const Color(0xFF334155),
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  child: Text(
                    'Go back',
                    style: GoogleFonts.outfit(fontWeight: FontWeight.w600),
                  ),
                ),
                const SizedBox(width: 12),
                ElevatedButton(
                  onPressed: () {
                    _bloc.add(SelectActivityForDetail(widget.activityId));
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  child: Text(
                    'Try again',
                    style: GoogleFonts.outfit(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

