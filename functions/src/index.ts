import * as admin from 'firebase-admin';
import { HttpsError, onCall } from 'firebase-functions/v2/https';

admin.initializeApp();

const db = admin.firestore();

type AppStatus =
  | 'applied'
  | 'approvedByBusiness'
  | 'rejected'
  | 'sampleSubmitted'
  | 'sampleApproved'
  | 'sampleRejected'
  | 'posted'
  | 'proofSubmitted'
  | 'proofApproved'
  | 'proofRejected'
  | 'paid';

function ensureAuthed(uid?: string) {
  if (!uid) {
    throw new HttpsError('unauthenticated', 'Authentication required.');
  }
}

export const depositCredits = onCall(async (request) => {
  ensureAuthed(request.auth?.uid);
  const { businessId, amount } = request.data as { businessId: string; amount: number };
  if (!businessId || !Number.isInteger(amount) || amount <= 0) {
    throw new HttpsError('invalid-argument', 'businessId and positive amount are required');
  }
  if (request.auth?.uid !== businessId) {
    throw new HttpsError('permission-denied', 'Cannot deposit to another business wallet');
  }

  await db.runTransaction(async (tx) => {
    const walletRef = db.collection('wallets').doc(businessId);
    const walletSnap = await tx.get(walletRef);
    const wallet = walletSnap.data() || { availableBalance: 0, heldBalance: 0, role: 'business' };

    tx.set(
      walletRef,
      {
        uid: businessId,
        role: wallet.role,
        availableBalance: (wallet.availableBalance || 0) + amount,
        heldBalance: wallet.heldBalance || 0,
        updatedAt: admin.firestore.FieldValue.serverTimestamp(),
      },
      { merge: true },
    );

    const ledgerRef = walletRef.collection('ledger').doc();
    tx.set(ledgerRef, {
      txId: ledgerRef.id,
      type: 'deposit',
      amount,
      direction: 'in',
      status: 'posted',
      reference: {},
      createdAt: admin.firestore.FieldValue.serverTimestamp(),
    });
  });

  return { ok: true };
});

export const approveCreator = onCall(async (request) => {
  ensureAuthed(request.auth?.uid);
  const { campaignId, applicationId } = request.data as { campaignId: string; applicationId: string };

  await db.runTransaction(async (tx) => {
    const appRef = db.collection('campaigns').doc(campaignId).collection('applications').doc(applicationId);
    const appSnap = await tx.get(appRef);
    if (!appSnap.exists) throw new HttpsError('not-found', 'Application not found');
    const app = appSnap.data()!;

    if (request.auth?.uid !== app.businessId) {
      throw new HttpsError('permission-denied', 'Only campaign owner can approve');
    }
    if (app.status !== 'applied') {
      throw new HttpsError('failed-precondition', 'Application is not in applied state');
    }

    const campaignRef = db.collection('campaigns').doc(campaignId);
    const campaignSnap = await tx.get(campaignRef);
    const campaign = campaignSnap.data();
    if (!campaign) throw new HttpsError('not-found', 'Campaign not found');

    const amount = campaign.payoutAmountGhs as number;
    const businessWalletRef = db.collection('wallets').doc(app.businessId);
    const businessWalletSnap = await tx.get(businessWalletRef);
    const bWallet = businessWalletSnap.data() || { availableBalance: 0, heldBalance: 0 };

    if ((bWallet.availableBalance || 0) < amount) {
      throw new HttpsError('failed-precondition', 'Insufficient wallet balance for hold');
    }

    const holdRef = db.collection('holds').doc();
    tx.set(holdRef, {
      holdId: holdRef.id,
      businessId: app.businessId,
      creatorId: app.creatorId,
      campaignId,
      applicationId,
      amount,
      status: 'active',
      createdAt: admin.firestore.FieldValue.serverTimestamp(),
      updatedAt: admin.firestore.FieldValue.serverTimestamp(),
    });

    tx.update(businessWalletRef, {
      availableBalance: (bWallet.availableBalance || 0) - amount,
      heldBalance: (bWallet.heldBalance || 0) + amount,
      updatedAt: admin.firestore.FieldValue.serverTimestamp(),
    });

    const holdLedgerRef = businessWalletRef.collection('ledger').doc();
    tx.set(holdLedgerRef, {
      txId: holdLedgerRef.id,
      type: 'hold',
      amount,
      direction: 'out',
      status: 'posted',
      reference: { campaignId, applicationId, holdId: holdRef.id },
      createdAt: admin.firestore.FieldValue.serverTimestamp(),
    });

    tx.update(appRef, {
      status: 'approvedByBusiness' as AppStatus,
      holdId: holdRef.id,
      'timestamps.approvedAt': admin.firestore.FieldValue.serverTimestamp(),
      updatedAt: admin.firestore.FieldValue.serverTimestamp(),
    });
  });

  return { ok: true };
});

export const approveProof = onCall(async (request) => {
  ensureAuthed(request.auth?.uid);
  const { campaignId, applicationId } = request.data as { campaignId: string; applicationId: string };

  await db.runTransaction(async (tx) => {
    const appRef = db.collection('campaigns').doc(campaignId).collection('applications').doc(applicationId);
    const appSnap = await tx.get(appRef);
    if (!appSnap.exists) throw new HttpsError('not-found', 'Application not found');
    const app = appSnap.data()!;

    if (request.auth?.uid !== app.businessId) {
      throw new HttpsError('permission-denied', 'Only campaign owner can approve proof');
    }
    if (app.status !== 'proofSubmitted') {
      throw new HttpsError('failed-precondition', 'Application is not in proofSubmitted state');
    }

    const campaignRef = db.collection('campaigns').doc(campaignId);
    const campaignSnap = await tx.get(campaignRef);
    const campaign = campaignSnap.data();
    if (!campaign) throw new HttpsError('not-found', 'Campaign not found');

    const latestProof = await tx.get(
      appRef.collection('submissions')
        .where('type', '==', 'proof')
        .orderBy('createdAt', 'desc')
        .limit(1),
    );
    if (latestProof.empty) {
      throw new HttpsError('failed-precondition', 'No proof submission found');
    }
    const proof = latestProof.docs[0].data();
    if (!proof.postUrl || typeof proof.postUrl !== 'string') {
      throw new HttpsError('failed-precondition', 'Proof must include postUrl');
    }
    if ((proof.declaredViews || 0) < (campaign.targetViews || 0)) {
      throw new HttpsError('failed-precondition', 'Declared views do not meet target');
    }

    const holdRef = db.collection('holds').doc(app.holdId);
    const holdSnap = await tx.get(holdRef);
    const hold = holdSnap.data();
    if (!hold || hold.status !== 'active') {
      throw new HttpsError('failed-precondition', 'No active hold for application');
    }

    const amount = hold.amount as number;
    const businessWalletRef = db.collection('wallets').doc(app.businessId);
    const creatorWalletRef = db.collection('wallets').doc(app.creatorId);
    const bWalletSnap = await tx.get(businessWalletRef);
    const cWalletSnap = await tx.get(creatorWalletRef);
    const bWallet = bWalletSnap.data() || { heldBalance: 0 };
    const cWallet = cWalletSnap.data() || { availableBalance: 0, heldBalance: 0, role: 'creator' };

    tx.update(businessWalletRef, {
      heldBalance: Math.max((bWallet.heldBalance || 0) - amount, 0),
      updatedAt: admin.firestore.FieldValue.serverTimestamp(),
    });
    tx.set(
      creatorWalletRef,
      {
        uid: app.creatorId,
        role: cWallet.role || 'creator',
        availableBalance: (cWallet.availableBalance || 0) + amount,
        heldBalance: cWallet.heldBalance || 0,
        updatedAt: admin.firestore.FieldValue.serverTimestamp(),
      },
      { merge: true },
    );

    const releaseLedgerRef = businessWalletRef.collection('ledger').doc();
    tx.set(releaseLedgerRef, {
      txId: releaseLedgerRef.id,
      type: 'release',
      amount,
      direction: 'in',
      status: 'posted',
      reference: { campaignId, applicationId, holdId: hold.holdId },
      createdAt: admin.firestore.FieldValue.serverTimestamp(),
    });

    const payoutLedgerRef = creatorWalletRef.collection('ledger').doc();
    tx.set(payoutLedgerRef, {
      txId: payoutLedgerRef.id,
      type: 'payout',
      amount,
      direction: 'in',
      status: 'posted',
      reference: { campaignId, applicationId, holdId: hold.holdId },
      createdAt: admin.firestore.FieldValue.serverTimestamp(),
    });

    tx.update(holdRef, {
      status: 'released',
      updatedAt: admin.firestore.FieldValue.serverTimestamp(),
    });

    tx.update(appRef, {
      status: 'paid' as AppStatus,
      'timestamps.proofApprovedAt': admin.firestore.FieldValue.serverTimestamp(),
      'timestamps.paidAt': admin.firestore.FieldValue.serverTimestamp(),
      updatedAt: admin.firestore.FieldValue.serverTimestamp(),
    });
  });

  return { ok: true };
});

export const refundHold = onCall(async (request) => {
  ensureAuthed(request.auth?.uid);
  const { holdId } = request.data as { holdId: string };

  await db.runTransaction(async (tx) => {
    const holdRef = db.collection('holds').doc(holdId);
    const holdSnap = await tx.get(holdRef);
    if (!holdSnap.exists) throw new HttpsError('not-found', 'Hold not found');
    const hold = holdSnap.data()!;

    if (request.auth?.uid !== hold.businessId) {
      throw new HttpsError('permission-denied', 'Only business owner can refund hold');
    }
    if (hold.status !== 'active') {
      throw new HttpsError('failed-precondition', 'Hold is not active');
    }

    const walletRef = db.collection('wallets').doc(hold.businessId);
    const walletSnap = await tx.get(walletRef);
    const wallet = walletSnap.data() || { availableBalance: 0, heldBalance: 0 };

    tx.update(walletRef, {
      availableBalance: (wallet.availableBalance || 0) + hold.amount,
      heldBalance: Math.max((wallet.heldBalance || 0) - hold.amount, 0),
      updatedAt: admin.firestore.FieldValue.serverTimestamp(),
    });

    const refundLedgerRef = walletRef.collection('ledger').doc();
    tx.set(refundLedgerRef, {
      txId: refundLedgerRef.id,
      type: 'refund',
      amount: hold.amount,
      direction: 'in',
      status: 'posted',
      reference: {
        campaignId: hold.campaignId,
        applicationId: hold.applicationId,
        holdId,
      },
      createdAt: admin.firestore.FieldValue.serverTimestamp(),
    });

    tx.update(holdRef, {
      status: 'refunded',
      updatedAt: admin.firestore.FieldValue.serverTimestamp(),
    });
  });

  return { ok: true };
});
