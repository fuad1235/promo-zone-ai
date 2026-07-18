import '../models/app_models.dart';

class StatusMachine {
  const StatusMachine._();

  static const Map<ApplicationStatus, Set<ApplicationStatus>> _allowed = {
    ApplicationStatus.applied: {
      ApplicationStatus.approvedByBusiness,
      ApplicationStatus.rejected,
    },
    ApplicationStatus.approvedByBusiness: {ApplicationStatus.sampleSubmitted},
    ApplicationStatus.sampleSubmitted: {
      ApplicationStatus.sampleApproved,
      ApplicationStatus.sampleRejected,
    },
    ApplicationStatus.sampleRejected: {ApplicationStatus.sampleSubmitted},
    ApplicationStatus.sampleApproved: {ApplicationStatus.posted},
    ApplicationStatus.posted: {ApplicationStatus.proofSubmitted},
    ApplicationStatus.proofSubmitted: {
      ApplicationStatus.proofApproved,
      ApplicationStatus.proofRejected,
    },
    ApplicationStatus.proofRejected: {ApplicationStatus.proofSubmitted},
    ApplicationStatus.proofApproved: {ApplicationStatus.paid},
    ApplicationStatus.rejected: {},
    ApplicationStatus.paid: {},
  };

  static bool canTransition(ApplicationStatus from, ApplicationStatus to) {
    return _allowed[from]?.contains(to) ?? false;
  }
}
