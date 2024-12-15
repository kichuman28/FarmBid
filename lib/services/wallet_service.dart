import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:uuid/uuid.dart';
import '../models/wallet.dart';

class WalletService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final _uuid = Uuid();

  Future<Wallet> getWallet(String userId) async {
    final doc = await _firestore.collection('wallets').doc(userId).get();
    if (!doc.exists) {
      // Create new wallet if it doesn't exist
      final wallet = Wallet(
        userId: userId,
        balance: 0,
        transactions: [],
        lockedFunds: {},
      );
      await _firestore.collection('wallets').doc(userId).set(wallet.toMap());
      return wallet;
    }
    return Wallet.fromMap(doc.data()!);
  }

  Future<void> addFunds(String userId, double amount) async {
    final walletRef = _firestore.collection('wallets').doc(userId);
    
    // First check if wallet exists
    final walletDoc = await walletRef.get();
    
    await _firestore.runTransaction((transaction) async {
      if (!walletDoc.exists) {
        // Create new wallet if it doesn't exist
        transaction.set(walletRef, {
          'userId': userId,
          'balance': amount,
          'transactions': [{
            'id': _uuid.v4(),
            'type': 'deposit',
            'amount': amount,
            'timestamp': DateTime.now().toIso8601String(),
            'description': 'Initial deposit'
          }],
          'lockedFunds': {},
        });
      } else {
        // Update existing wallet
        transaction.update(walletRef, {
          'balance': FieldValue.increment(amount),
          'transactions': FieldValue.arrayUnion([{
            'id': _uuid.v4(),
            'type': 'deposit',
            'amount': amount,
            'timestamp': DateTime.now().toIso8601String(),
            'description': 'Wallet recharge'
          }]),
        });
      }

      // Log the recharge
      final rechargeRef = _firestore.collection('recharges').doc();
      transaction.set(rechargeRef, {
        'userId': userId,
        'amount': amount,
        'timestamp': FieldValue.serverTimestamp(),
      });
    });
  }

  Future<bool> lockFundsForBid(
      String userId, String auctionId, double amount) async {
    final walletRef = _firestore.collection('wallets').doc(userId);

    try {
      await _firestore.runTransaction((transaction) async {
        final walletDoc = await transaction.get(walletRef);
        final wallet = Wallet.fromMap(walletDoc.data()!);

        if (wallet.availableBalance < amount) {
          throw Exception('Insufficient funds');
        }

        // Release previously locked funds for this auction if any
        final previousLock = wallet.lockedFunds[auctionId] ?? 0;

        final newTransaction = WalletTransaction(
          id: _uuid.v4(),
          type: 'lock',
          amount: amount,
          timestamp: DateTime.now(),
          relatedAuctionId: auctionId,
          description: 'Funds locked for auction bid',
        );

        Map<String, double> newLockedFunds = Map.from(wallet.lockedFunds);
        newLockedFunds[auctionId] = amount;

        // If there was a previous lock, we need to adjust the balance
        final balanceAdjustment = amount - previousLock;

        transaction.update(walletRef, {
          'balance': wallet.balance, // Balance stays the same
          'lockedFunds': newLockedFunds,
          'transactions': FieldValue.arrayUnion([newTransaction.toMap()]),
        });
      });
      return true;
    } catch (e) {
      print('Error locking funds: $e');
      return false;
    }
  }

  Future<void> transferFundsToSeller(
      String auctionId, String buyerId, String sellerId, double amount) async {
    final buyerWalletRef = _firestore.collection('wallets').doc(buyerId);
    final sellerWalletRef = _firestore.collection('wallets').doc(sellerId);

    await _firestore.runTransaction((transaction) async {
      // First, get all documents
      final buyerWalletDoc = await transaction.get(buyerWalletRef);
      final sellerWalletDoc = await transaction.get(sellerWalletRef);

      if (!buyerWalletDoc.exists || !sellerWalletDoc.exists) {
        throw Exception('Wallet not found');
      }

      // Then process the data
      final buyerWallet = Wallet.fromMap(buyerWalletDoc.data()!);
      final sellerWallet = Wallet.fromMap(sellerWalletDoc.data()!);

      // Prepare the updates
      Map<String, double> newBuyerLockedFunds = Map.from(buyerWallet.lockedFunds);
      newBuyerLockedFunds.remove(auctionId);

      final buyerTransaction = WalletTransaction(
        id: _uuid.v4(),
        type: 'transfer',
        amount: -amount,
        timestamp: DateTime.now(),
        relatedAuctionId: auctionId,
        description: 'Auction payment',
      );

      final sellerTransaction = WalletTransaction(
        id: _uuid.v4(),
        type: 'transfer',
        amount: amount,
        timestamp: DateTime.now(),
        relatedAuctionId: auctionId,
        description: 'Auction payment received',
      );

      // Finally, perform all updates
      transaction.update(buyerWalletRef, {
        'balance': buyerWallet.balance - amount,
        'lockedFunds': newBuyerLockedFunds,
        'transactions': FieldValue.arrayUnion([buyerTransaction.toMap()]),
      });

      transaction.update(sellerWalletRef, {
        'balance': sellerWallet.balance + amount,
        'transactions': FieldValue.arrayUnion([sellerTransaction.toMap()]),
      });
    });
  }

  Stream<Wallet> getWalletStream(String userId) {
    return _firestore.collection('wallets').doc(userId).snapshots().map((doc) {
      if (!doc.exists) {
        return Wallet(
          userId: userId,
          balance: 0,
          transactions: [],
          lockedFunds: {},
        );
      }
      return Wallet.fromMap(doc.data()!);
    });
  }
}
