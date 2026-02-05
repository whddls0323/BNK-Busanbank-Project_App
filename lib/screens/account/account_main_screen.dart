// 2025/12/29 - 계좌 메인 화면 (SOL 스타일) - 작성자: 진원
// 2026/01/04 - 잔액조회 기능 제거 - 작성자: 진원
// 2026/01/04 - 최근 거래 3개 표시 기능 추가 - 작성자: 진원
// 2026/01/04 - 계좌명 표시 기능 추가 - 작성자: 진원
// 2026/01/04 - 통장 해지 기능 추가 - 작성자: 진원
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../services/account_service.dart';
import '../../models/account.dart';
import '../../models/transaction.dart';
import 'transfer_screen.dart';
import 'transaction_history_screen.dart';
import 'package:intl/intl.dart';

class AccountMainScreen extends StatefulWidget {
  final String accountNo;

  const AccountMainScreen({super.key, required this.accountNo});

  @override
  State<AccountMainScreen> createState() => _AccountMainScreenState();
}

class _AccountMainScreenState extends State<AccountMainScreen> {
  final AccountService _accountService = AccountService();
  final NumberFormat _currencyFormat = NumberFormat('#,###');
  final DateFormat _dateFormat = DateFormat('MM/dd HH:mm');

  int? _balance;
  Account? _accountInfo; // 계좌 정보
  List<Transaction> _recentTransactions = [];
  bool _isLoading = true;
  bool _showBalance = true;

  @override
  void initState() {
    super.initState();
    _loadBalance();
  }

  Future<void> _loadBalance() async {
    try {
      setState(() => _isLoading = true);

      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final userId = authProvider.userNo;

      final balanceResult = await _accountService.getBalance(widget.accountNo);
      final transactions =
          await _accountService.getTransactionHistoryByAccount(widget.accountNo);

      // 계좌 정보 가져오기
      Account? account;
      if (userId != null) {
        final accounts = await _accountService.getUserAccounts(userId);
        account = accounts.firstWhere(
          (acc) => acc.accountNo == widget.accountNo,
          orElse: () => Account(
            accountNo: widget.accountNo,
            userId: userId,
            balance: balanceResult['balance'] ?? 0,
          ),
        );
      }

      if (mounted) {
        setState(() {
          _balance = balanceResult['balance'];
          _accountInfo = account;
          // 최근 거래 3개만 가져오기
          _recentTransactions = transactions.take(3).toList();
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('데이터 조회 실패: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('내 계좌'),
        backgroundColor: const Color(0xFF2196F3),
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: Icon(_showBalance ? Icons.visibility : Icons.visibility_off),
            onPressed: () {
              setState(() => _showBalance = !_showBalance);
            },
            tooltip: _showBalance ? '잔액 숨기기' : '잔액 표시',
          ),
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert),
            onSelected: (value) {
              if (value == 'close') {
                _showCloseAccountDialog();
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'close',
                child: Row(
                  children: [
                    Icon(Icons.cancel, color: Colors.red),
                    SizedBox(width: 8),
                    Text('통장 해지'),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadBalance,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                child: Column(
                  children: [
                    // 계좌 잔액 카드
                    _buildBalanceCard(),
                    const SizedBox(height: 20),

                    // 주요 기능 버튼
                    _buildQuickActions(),
                    const SizedBox(height: 20),

                    // 최근 거래내역 미리보기
                    _buildRecentTransactions(),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildBalanceCard() {
    return Container(
      margin: const EdgeInsets.all(20),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF2196F3), Color(0xFF1976D2)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.blue.withOpacity(0.3),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                _accountInfo?.productName ?? _accountInfo?.accountType ?? 'TK Bank',
                style: const TextStyle(
                  color: Colors.white70,
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.white24,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: const Text(
                  '입출금',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            widget.accountNo,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 16,
              letterSpacing: 1.2,
            ),
          ),
          const SizedBox(height: 20),
          const Text(
            '현재 잔액',
            style: TextStyle(
              color: Colors.white70,
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            _showBalance
                ? '${_currencyFormat.format(_balance ?? 0)}원'
                : '●●●●●●원',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 36,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActions() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '빠른 서비스',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildActionButton(
                  icon: Icons.send,
                  label: '이체',
                  color: const Color(0xFF2196F3),
                  onTap: () async {
                    final result = await Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) =>
                            TransferScreen(fromAccountNo: widget.accountNo),
                      ),
                    );
                    // 이체 성공시 잔액 새로고침
                    if (result == true) {
                      _loadBalance();
                    }
                  },
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildActionButton(
                  icon: Icons.receipt_long,
                  label: '거래내역',
                  color: const Color(0xFFFF9800),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => TransactionHistoryScreen(
                            accountNo: widget.accountNo),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey.shade200),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.1),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          children: [
            Icon(icon, size: 32, color: color),
            const SizedBox(height: 8),
            Text(
              label,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRecentTransactions() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                '최근 거래',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              TextButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) =>
                          TransactionHistoryScreen(accountNo: widget.accountNo),
                    ),
                  );
                },
                child: const Text('전체보기'),
              ),
            ],
          ),
          const SizedBox(height: 8),
          _recentTransactions.isEmpty
              ? Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade50,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.grey.shade200),
                  ),
                  child: Center(
                    child: Column(
                      children: [
                        Icon(Icons.receipt_long,
                            size: 48, color: Colors.grey.shade400),
                        const SizedBox(height: 8),
                        Text(
                          '거래내역이 없습니다',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey.shade600,
                          ),
                        ),
                      ],
                    ),
                  ),
                )
              : Column(
                  children: _recentTransactions
                      .map((transaction) =>
                          _buildTransactionItem(transaction))
                      .toList(),
                ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _buildTransactionItem(Transaction transaction) {
    final bool isDeposit = transaction.isDeposit(widget.accountNo);
    final Color amountColor = isDeposit ? Colors.blue : Colors.red;
    final String amountSign = isDeposit ? '+' : '-';

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      child: ListTile(
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: Icon(
          isDeposit ? Icons.arrow_downward : Icons.arrow_upward,
          color: amountColor,
          size: 24,
        ),
        title: Text(
          isDeposit
              ? '${transaction.fromAccountNo}에서'
              : '${transaction.toAccountNo}로',
          style: const TextStyle(fontSize: 14),
          overflow: TextOverflow.ellipsis,
        ),
        subtitle: Text(
          _formatTransactionDate(transaction.transactionDate),
          style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
        ),
        trailing: Text(
          '$amountSign${_currencyFormat.format(transaction.amount)}원',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: amountColor,
          ),
        ),
      ),
    );
  }

  String _formatTransactionDate(String dateStr) {
    try {
      final date = DateTime.parse(dateStr.replaceAll(' ', 'T'));
      return _dateFormat.format(date);
    } catch (e) {
      return dateStr;
    }
  }

  // 2026/01/04 - 통장 해지 다이얼로그 - 작성자: 진원
  Future<void> _showCloseAccountDialog() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final userId = authProvider.userNo;

    if (userId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('로그인이 필요합니다')),
      );
      return;
    }

    // 잔액이 있는 경우 처리
    if (_balance != null && _balance! > 0) {
      // 다른 계좌 목록 조회
      try {
        final accounts = await _accountService.getUserAccounts(userId);
        final otherAccounts = accounts
            .where((acc) => acc.accountNo != widget.accountNo)
            .toList();

        if (!mounted) return;

        if (otherAccounts.isEmpty) {
          // 다른 계좌가 없으면 잔액이 있어서 해지 불가
          showDialog(
            context: context,
            builder: (context) => AlertDialog(
              title: const Text('통장 해지 불가'),
              content: const Text(
                '잔액이 남아있어 해지할 수 없습니다.\n'
                '잔액을 이동할 다른 계좌가 없습니다.\n'
                '잔액을 먼저 출금해주세요.',
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('확인'),
                ),
              ],
            ),
          );
          return;
        }

        // 잔액 이동할 계좌 선택
        final selectedAccount = await showDialog<Account>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('잔액 이동'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '현재 잔액: ${_currencyFormat.format(_balance)}원',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF2196F3),
                  ),
                ),
                const SizedBox(height: 16),
                const Text('잔액을 이동할 계좌를 선택하세요:'),
                const SizedBox(height: 12),
                ...otherAccounts.map((account) => ListTile(
                      leading: const Icon(Icons.account_balance_wallet,
                          color: Color(0xFF2196F3)),
                      title: Text(account.accountNo),
                      subtitle: Text(
                        account.productName ??
                            account.accountType ??
                            'TK Bank 계좌',
                      ),
                      onTap: () => Navigator.pop(context, account),
                    )),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('취소'),
              ),
            ],
          ),
        );

        if (selectedAccount == null || !mounted) return;

        // 해지 확인
        final confirmed = await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('통장 해지 확인'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  '정말 이 계좌를 해지하시겠습니까?',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 16),
                Text('해지할 계좌: ${widget.accountNo}'),
                const SizedBox(height: 8),
                Text(
                  '잔액: ${_currencyFormat.format(_balance)}원',
                  style: const TextStyle(color: Colors.red),
                ),
                const SizedBox(height: 8),
                Text('이동할 계좌: ${selectedAccount.accountNo}'),
                const SizedBox(height: 16),
                const Text(
                  '⚠️ 해지 후에는 복구할 수 없습니다.',
                  style: TextStyle(color: Colors.red, fontSize: 12),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('취소'),
              ),
              ElevatedButton(
                onPressed: () => Navigator.pop(context, true),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  foregroundColor: Colors.white,
                ),
                child: const Text('해지'),
              ),
            ],
          ),
        );

        if (confirmed != true || !mounted) return;

        // 계좌 해지 실행
        await _performCloseAccount(userId, selectedAccount.accountNo);
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('오류 발생: $e')),
          );
        }
      }
    } else {
      // 잔액이 0원인 경우 바로 해지
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('통장 해지 확인'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                '정말 이 계좌를 해지하시겠습니까?',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              Text('해지할 계좌: ${widget.accountNo}'),
              const SizedBox(height: 8),
              const Text('잔액: 0원'),
              const SizedBox(height: 16),
              const Text(
                '⚠️ 해지 후에는 복구할 수 없습니다.',
                style: TextStyle(color: Colors.red, fontSize: 12),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('취소'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(context, true),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
              ),
              child: const Text('해지'),
            ),
          ],
        ),
      );

      if (confirmed == true && mounted) {
        await _performCloseAccount(userId, null);
      }
    }
  }

  // 2026/01/04 - 계좌 해지 실행 - 작성자: 진원
  Future<void> _performCloseAccount(
      int userId, String? transferToAccountNo) async {
    try {
      setState(() => _isLoading = true);

      final result = await _accountService.closeAccount(
        userId: userId,
        accountNo: widget.accountNo,
        transferToAccountNo: transferToAccountNo,
      );

      if (mounted) {
        setState(() => _isLoading = false);

        if (result['success'] == true) {
          showDialog(
            context: context,
            barrierDismissible: false,
            builder: (context) => AlertDialog(
              title: Row(
                children: [
                  Icon(Icons.check_circle, color: Colors.green, size: 28),
                  const SizedBox(width: 8),
                  const Text('해지 완료'),
                ],
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('계좌번호: ${widget.accountNo}'),
                  const SizedBox(height: 8),
                  const Text('통장이 정상적으로 해지되었습니다.'),
                  if (transferToAccountNo != null) ...[
                    const SizedBox(height: 8),
                    Text(
                      '잔액이 ${transferToAccountNo}로 이동되었습니다.',
                      style: const TextStyle(color: Color(0xFF2196F3)),
                    ),
                  ],
                ],
              ),
              actions: [
                ElevatedButton(
                  onPressed: () {
                    Navigator.pop(context); // 다이얼로그 닫기
                    Navigator.pop(context, true); // 계좌 화면 닫기
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF2196F3),
                    foregroundColor: Colors.white,
                  ),
                  child: const Text('확인'),
                ),
              ],
            ),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(result['error'] ?? '계좌 해지 실패')),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('계좌 해지 실패: $e')),
        );
      }
    }
  }
}
