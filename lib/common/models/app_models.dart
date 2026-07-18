import 'package:cloud_firestore/cloud_firestore.dart';

enum UserRole { creator, business, admin }

enum CampaignStatus { draft, published, closed }

enum ApplicationStatus {
  applied,
  approvedByBusiness,
  rejected,
  sampleSubmitted,
  sampleApproved,
  sampleRejected,
  posted,
  proofSubmitted,
  proofApproved,
  proofRejected,
  paid,
}

enum SubmissionType { sample, proof }

enum ReviewStatus { pending, approved, rejected }

enum LedgerType { deposit, hold, release, payout, refund, adjustment }

enum LedgerDirection { inFlow, outFlow }

enum LedgerStatus { pending, posted, failed }

enum HoldStatus { active, released, refunded }

UserRole parseRole(String value) => UserRole.values.firstWhere(
      (e) => e.name == value,
      orElse: () => UserRole.creator,
    );

ApplicationStatus parseApplicationStatus(String value) {
  const map = {
    'applied': ApplicationStatus.applied,
    'approvedByBusiness': ApplicationStatus.approvedByBusiness,
    'approved_by_business': ApplicationStatus.approvedByBusiness,
    'rejected': ApplicationStatus.rejected,
    'sampleSubmitted': ApplicationStatus.sampleSubmitted,
    'sample_submitted': ApplicationStatus.sampleSubmitted,
    'sampleApproved': ApplicationStatus.sampleApproved,
    'sample_approved': ApplicationStatus.sampleApproved,
    'sampleRejected': ApplicationStatus.sampleRejected,
    'sample_rejected': ApplicationStatus.sampleRejected,
    'posted': ApplicationStatus.posted,
    'proofSubmitted': ApplicationStatus.proofSubmitted,
    'proof_submitted': ApplicationStatus.proofSubmitted,
    'proofApproved': ApplicationStatus.proofApproved,
    'proof_approved': ApplicationStatus.proofApproved,
    'proofRejected': ApplicationStatus.proofRejected,
    'proof_rejected': ApplicationStatus.proofRejected,
    'paid': ApplicationStatus.paid,
  };
  return map[value] ?? ApplicationStatus.applied;
}

String applicationStatusToApi(ApplicationStatus status) {
  return switch (status) {
    ApplicationStatus.applied => 'applied',
    ApplicationStatus.approvedByBusiness => 'approved_by_business',
    ApplicationStatus.rejected => 'rejected',
    ApplicationStatus.sampleSubmitted => 'sample_submitted',
    ApplicationStatus.sampleApproved => 'sample_approved',
    ApplicationStatus.sampleRejected => 'sample_rejected',
    ApplicationStatus.posted => 'posted',
    ApplicationStatus.proofSubmitted => 'proof_submitted',
    ApplicationStatus.proofApproved => 'proof_approved',
    ApplicationStatus.proofRejected => 'proof_rejected',
    ApplicationStatus.paid => 'paid',
  };
}

CampaignStatus parseCampaignStatus(String value) => CampaignStatus.values
    .firstWhere((e) => e.name == value, orElse: () => CampaignStatus.draft);

SubmissionType parseSubmissionType(String value) => SubmissionType.values
    .firstWhere((e) => e.name == value, orElse: () => SubmissionType.sample);

ReviewStatus parseReviewStatus(String value) => ReviewStatus.values.firstWhere(
      (e) => e.name == value,
      orElse: () => ReviewStatus.pending,
    );

LedgerType parseLedgerType(String value) => LedgerType.values.firstWhere(
      (e) => e.name == value,
      orElse: () => LedgerType.adjustment,
    );

LedgerDirection parseLedgerDirection(String value) {
  if (value == 'out') return LedgerDirection.outFlow;
  return LedgerDirection.inFlow;
}

LedgerStatus parseLedgerStatus(String value) => LedgerStatus.values.firstWhere(
      (e) => e.name == value,
      orElse: () => LedgerStatus.pending,
    );

HoldStatus parseHoldStatus(String value) => HoldStatus.values.firstWhere(
      (e) => e.name == value,
      orElse: () => HoldStatus.active,
    );

DateTime parseDate(dynamic value) {
  if (value is Timestamp) return value.toDate();
  if (value is DateTime) return value;
  if (value is String) {
    final parsed = DateTime.tryParse(value);
    if (parsed != null) return parsed;
  }
  return DateTime.now();
}

Map<String, dynamic> tsNowData(Map<String, dynamic> source) {
  return {...source, 'updatedAt': FieldValue.serverTimestamp()};
}
