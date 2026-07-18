import 'app_models.dart';

class AppUser {
  const AppUser({
    required this.uid,
    required this.role,
    required this.displayName,
    required this.email,
    this.phone,
    required this.createdAt,
    required this.updatedAt,
  });

  final String uid;
  final UserRole role;
  final String displayName;
  final String email;
  final String? phone;
  final DateTime createdAt;
  final DateTime updatedAt;

  factory AppUser.fromJson(Map<String, dynamic> json) => AppUser(
        uid: json['uid'] as String,
        role: parseRole((json['role'] ?? 'creator') as String),
        displayName: (json['displayName'] ?? '') as String,
        email: (json['email'] ?? '') as String,
        phone: json['phone'] as String?,
        createdAt: parseDate(json['createdAt']),
        updatedAt: parseDate(json['updatedAt']),
      );

  Map<String, dynamic> toJson() => {
        'uid': uid,
        'role': role.name,
        'displayName': displayName,
        'email': email,
        'phone': phone,
        'createdAt': createdAt,
        'updatedAt': updatedAt,
      };
}

class CreatorHandle {
  const CreatorHandle({
    required this.id,
    required this.platform,
    required this.username,
    required this.profileUrl,
    required this.verified,
    required this.createdAt,
  });

  final String id;
  final String platform;
  final String username;
  final String profileUrl;
  final bool verified;
  final DateTime createdAt;

  factory CreatorHandle.fromJson(String id, Map<String, dynamic> json) =>
      CreatorHandle(
        id: id,
        platform: (json['platform'] ?? '') as String,
        username: (json['username'] ?? '') as String,
        profileUrl: (json['profileUrl'] ?? '') as String,
        verified: (json['verified'] ?? false) as bool,
        createdAt: parseDate(json['createdAt']),
      );

  Map<String, dynamic> toJson() => {
        'platform': platform,
        'username': username,
        'profileUrl': profileUrl,
        'verified': verified,
        'createdAt': createdAt,
      };
}

class Campaign {
  const Campaign({
    required this.id,
    required this.businessId,
    required this.title,
    required this.description,
    required this.productImages,
    required this.platform,
    required this.targetViews,
    required this.payoutAmountGhs,
    required this.creatorsNeeded,
    required this.rules,
    required this.startDate,
    required this.endDate,
    required this.status,
    required this.createdAt,
    required this.updatedAt,
  });

  final String id;
  final String businessId;
  final String title;
  final String description;
  final List<String> productImages;
  final String platform;
  final int targetViews;
  final int payoutAmountGhs;
  final int creatorsNeeded;
  final Map<String, dynamic> rules;
  final DateTime startDate;
  final DateTime endDate;
  final CampaignStatus status;
  final DateTime createdAt;
  final DateTime updatedAt;

  factory Campaign.fromJson(String id, Map<String, dynamic> json) => Campaign(
        id: id,
        businessId: (json['businessId'] ?? '') as String,
        title: (json['title'] ?? '') as String,
        description: (json['description'] ?? '') as String,
        productImages: ((json['productImages'] ?? []) as List)
            .map((e) => e.toString())
            .toList(),
        platform: (json['platform'] ?? '') as String,
        targetViews: (json['targetViews'] ?? 0) as int,
        payoutAmountGhs: (json['payoutAmountGhs'] ?? 0) as int,
        creatorsNeeded: (json['creatorsNeeded'] ?? 1) as int,
        rules: (json['rules'] ?? <String, dynamic>{}) as Map<String, dynamic>,
        startDate: parseDate(json['startDate']),
        endDate: parseDate(json['endDate']),
        status: parseCampaignStatus((json['status'] ?? 'draft') as String),
        createdAt: parseDate(json['createdAt']),
        updatedAt: parseDate(json['updatedAt']),
      );

  Map<String, dynamic> toJson() => {
        'businessId': businessId,
        'title': title,
        'description': description,
        'productImages': productImages,
        'platform': platform,
        'targetViews': targetViews,
        'payoutAmountGhs': payoutAmountGhs,
        'creatorsNeeded': creatorsNeeded,
        'rules': rules,
        'startDate': startDate,
        'endDate': endDate,
        'status': status.name,
        'createdAt': createdAt,
        'updatedAt': updatedAt,
      };
}

class Application {
  const Application({
    required this.id,
    required this.campaignId,
    required this.businessId,
    required this.creatorId,
    required this.creatorHandleRef,
    required this.creatorSnapshot,
    required this.status,
    required this.timestamps,
    this.holdId,
    required this.createdAt,
    required this.updatedAt,
  });

  final String id;
  final String campaignId;
  final String businessId;
  final String creatorId;
  final Map<String, dynamic> creatorHandleRef;
  final Map<String, dynamic> creatorSnapshot;
  final ApplicationStatus status;
  final Map<String, dynamic> timestamps;
  final String? holdId;
  final DateTime createdAt;
  final DateTime updatedAt;

  factory Application.fromJson(String id, Map<String, dynamic> json) =>
      Application(
        id: id,
        campaignId: (json['campaignId'] ?? '') as String,
        businessId: (json['businessId'] ?? '') as String,
        creatorId: (json['creatorId'] ?? '') as String,
        creatorHandleRef: (json['creatorHandleRef'] ?? <String, dynamic>{})
            as Map<String, dynamic>,
        creatorSnapshot: (json['creatorSnapshot'] ?? <String, dynamic>{})
            as Map<String, dynamic>,
        status: parseApplicationStatus((json['status'] ?? 'applied') as String),
        timestamps:
            (json['timestamps'] ?? <String, dynamic>{}) as Map<String, dynamic>,
        holdId: json['holdId'] as String?,
        createdAt: parseDate(json['createdAt']),
        updatedAt: parseDate(json['updatedAt']),
      );

  Map<String, dynamic> toJson() => {
        'campaignId': campaignId,
        'businessId': businessId,
        'creatorId': creatorId,
        'creatorHandleRef': creatorHandleRef,
        'creatorSnapshot': creatorSnapshot,
        'status': status.name,
        'timestamps': timestamps,
        'holdId': holdId,
        'createdAt': createdAt,
        'updatedAt': updatedAt,
      };
}

class Submission {
  const Submission({
    required this.id,
    required this.type,
    required this.message,
    required this.mediaUrls,
    this.postUrl,
    required this.screenshots,
    this.declaredViews,
    required this.status,
    this.reviewerMessage,
    required this.createdAt,
    required this.updatedAt,
  });

  final String id;
  final SubmissionType type;
  final String message;
  final List<String> mediaUrls;
  final String? postUrl;
  final List<String> screenshots;
  final int? declaredViews;
  final ReviewStatus status;
  final String? reviewerMessage;
  final DateTime createdAt;
  final DateTime updatedAt;

  factory Submission.fromJson(String id, Map<String, dynamic> json) =>
      Submission(
        id: id,
        type: parseSubmissionType((json['type'] ?? 'sample') as String),
        message: (json['message'] ?? '') as String,
        mediaUrls: ((json['mediaUrls'] ?? []) as List)
            .map((e) => e.toString())
            .toList(),
        postUrl: json['postUrl'] as String?,
        screenshots: ((json['screenshots'] ?? []) as List)
            .map((e) => e.toString())
            .toList(),
        declaredViews: json['declaredViews'] as int?,
        status: parseReviewStatus((json['status'] ?? 'pending') as String),
        reviewerMessage: json['reviewerMessage'] as String?,
        createdAt: parseDate(json['createdAt']),
        updatedAt: parseDate(json['updatedAt']),
      );

  Map<String, dynamic> toJson() => {
        'type': type.name,
        'message': message,
        'mediaUrls': mediaUrls,
        'postUrl': postUrl,
        'screenshots': screenshots,
        'declaredViews': declaredViews,
        'status': status.name,
        'reviewerMessage': reviewerMessage,
        'createdAt': createdAt,
        'updatedAt': updatedAt,
      };
}

class Wallet {
  const Wallet({
    required this.uid,
    required this.role,
    required this.availableBalance,
    required this.heldBalance,
    required this.updatedAt,
  });

  final String uid;
  final UserRole role;
  final int availableBalance;
  final int heldBalance;
  final DateTime updatedAt;

  factory Wallet.fromJson(Map<String, dynamic> json) => Wallet(
        uid: (json['uid'] ?? '') as String,
        role: parseRole((json['role'] ?? 'creator') as String),
        availableBalance: (json['availableBalance'] ?? 0) as int,
        heldBalance: (json['heldBalance'] ?? 0) as int,
        updatedAt: parseDate(json['updatedAt']),
      );

  Map<String, dynamic> toJson() => {
        'uid': uid,
        'role': role.name,
        'availableBalance': availableBalance,
        'heldBalance': heldBalance,
        'updatedAt': updatedAt,
      };
}

class LedgerEntry {
  const LedgerEntry({
    required this.id,
    required this.type,
    required this.amount,
    required this.direction,
    required this.status,
    required this.reference,
    required this.createdAt,
  });

  final String id;
  final LedgerType type;
  final int amount;
  final LedgerDirection direction;
  final LedgerStatus status;
  final Map<String, dynamic> reference;
  final DateTime createdAt;

  factory LedgerEntry.fromJson(String id, Map<String, dynamic> json) =>
      LedgerEntry(
        id: id,
        type: parseLedgerType((json['type'] ?? 'adjustment') as String),
        amount: (json['amount'] ?? 0) as int,
        direction: parseLedgerDirection((json['direction'] ?? 'in').toString()),
        status: parseLedgerStatus((json['status'] ?? 'pending') as String),
        reference:
            (json['reference'] ?? <String, dynamic>{}) as Map<String, dynamic>,
        createdAt: parseDate(json['createdAt']),
      );

  Map<String, dynamic> toJson() => {
        'txId': id,
        'type': type.name,
        'amount': amount,
        'direction': direction == LedgerDirection.inFlow ? 'in' : 'out',
        'status': status.name,
        'reference': reference,
        'createdAt': createdAt,
      };
}
