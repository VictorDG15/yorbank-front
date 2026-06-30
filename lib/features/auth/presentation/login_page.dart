import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:hive_flutter/hive_flutter.dart';

import '../../../app/theme/app_colors.dart';
import '../data/auth_repository.dart';
import 'auth_controller.dart';

enum _LoginStep { identity, key }

class LoginPage extends ConsumerStatefulWidget {
  const LoginPage({super.key});

  @override
  ConsumerState<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends ConsumerState<LoginPage> {
  static const _rememberedLoginKey = 'remembered_login';

  final documentNumber = TextEditingController();
  final cardNumber = TextEditingController();
  final internetKey = TextEditingController();

  bool rememberUser = false;
  bool obscureKey = true;
  bool documentNumberError = false;
  bool cardNumberError = false;
  int selectedTab = 0;
  String selectedDocType = 'DNI';
  _LoginStep step = _LoginStep.identity;
  LoginChallenge? challenge;
  int _formVersion = 0;

  bool get isCompany => selectedTab == 1;
  String get segment => isCompany ? 'EMPRESAS' : 'PERSONAS';

  @override
  void initState() {
    super.initState();
    _restoreRememberedIdentity();
  }

  @override
  void dispose() {
    documentNumber.dispose();
    cardNumber.dispose();
    internetKey.dispose();
    super.dispose();
  }

  void _showWhiteBottomSheet(Widget child) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      barrierColor: Colors.black54,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
      ),
      builder: (_) => child,
    );
  }

  void _changeTab(int value) {
    _cancelPendingAuth();
    _clearRememberedIdentity();
    setState(() {
      selectedTab = value;
      selectedDocType = value == 1 ? 'RUC' : 'DNI';
      documentNumber.clear();
      cardNumber.clear();
      internetKey.clear();
      documentNumberError = false;
      cardNumberError = false;
      challenge = null;
      step = _LoginStep.identity;
    });
  }

  void _showDocTypeSheet() {
    if (isCompany) return;
    _showWhiteBottomSheet(
      _DocTypeSheet(
        current: selectedDocType,
        onSelected: (value) {
          _cancelPendingAuth();
          setState(() {
            selectedDocType = value;
            documentNumber.clear();
            documentNumberError = false;
          });
          Navigator.pop(context);
        },
      ),
    );
  }

  void _showForgotSheet() {
    _showWhiteBottomSheet(const _ForgotKeySheet());
  }

  void _showShortcutSheet(String title, List<_ShortcutOption> options) {
    _showWhiteBottomSheet(_OptionsSheet(title: title, options: options));
  }

  void _cancelPendingAuth() {
    _formVersion++;
    ref.read(authControllerProvider.notifier).cancelPending();
  }

  void _backToIdentity() {
    _cancelPendingAuth();
    _clearRememberedIdentity();
    setState(() {
      challenge = null;
      internetKey.clear();
      step = _LoginStep.identity;
    });
  }

  Future<void> _restoreRememberedIdentity() async {
    final box = await Hive.openBox('app_state');
    final raw = box.get(_rememberedLoginKey);
    if (raw is! Map) return;

    final restored = LoginChallenge(
      segment: raw['segment']?.toString() ?? 'PERSONAS',
      documentType: raw['documentType']?.toString() ?? 'DNI',
      documentNumber: raw['documentNumber']?.toString() ?? '',
      cardNumber: raw['cardNumber']?.toString() ?? '',
      maskedCard: raw['maskedCard']?.toString() ?? '******',
      cardType: raw['cardType']?.toString() ?? 'Tarjeta YBank',
    );

    if (restored.documentNumber.isEmpty || restored.cardNumber.isEmpty) return;
    if (!mounted) return;

    setState(() {
      selectedTab = restored.segment == 'EMPRESAS' ? 1 : 0;
      selectedDocType = restored.documentType;
      documentNumber.text = restored.documentNumber;
      cardNumber.text = _formatCard(restored.cardNumber);
      rememberUser = true;
      challenge = restored;
      step = _LoginStep.key;
    });
  }

  Future<void> _rememberIdentity(LoginChallenge value) async {
    final box = await Hive.openBox('app_state');
    await box.put(_rememberedLoginKey, {
      'segment': value.segment,
      'documentType': value.documentType,
      'documentNumber': value.documentNumber,
      'cardNumber': value.cardNumber,
      'maskedCard': value.maskedCard,
      'cardType': value.cardType,
    });
  }

  Future<void> _clearRememberedIdentity() async {
    final box = await Hive.openBox('app_state');
    await box.delete(_rememberedLoginKey);
  }

  Future<void> _continueToKey() async {
    final document = documentNumber.text.trim();
    final card = _onlyDigits(cardNumber.text);
    debugPrint(
      'YBank prepareLogin tap segment=$segment type=$selectedDocType doc=$document cardLength=${card.length}',
    );
    final cardIncomplete = card.length != 16;
    final documentRequiredLength = selectedDocType == 'RUC'
        ? 11
        : selectedDocType == 'DNI'
        ? 8
        : 12;
    final documentIncomplete = document.length != documentRequiredLength;

    if (documentIncomplete || cardIncomplete) {
      debugPrint('YBank prepareLogin blocked by local validation');
      setState(() {
        documentNumberError = documentIncomplete;
        cardNumberError = cardIncomplete;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            documentIncomplete
                ? 'Completa el numero de documento'
                : cardIncomplete
                ? 'Completa los 16 numeros de la tarjeta'
                : selectedDocType == 'RUC'
                ? 'Ingresa RUC y numero de tarjeta'
                : 'Ingresa documento y numero de tarjeta',
          ),
        ),
      );
      return;
    }

    setState(() {
      documentNumberError = false;
      cardNumberError = false;
    });
    final requestVersion = ++_formVersion;
    final result = await ref
        .read(authControllerProvider.notifier)
        .prepareLogin(
          segment: segment,
          documentType: selectedDocType,
          documentNumber: document,
          cardNumber: card,
        );

    if (!mounted || requestVersion != _formVersion) return;
    if (result == null) {
      debugPrint('YBank prepareLogin failed');
      _showCurrentError('No se pudo validar la tarjeta');
      return;
    }

    debugPrint('YBank prepareLogin success maskedCard=${result.maskedCard}');
    await _rememberIdentity(result);
    if (!mounted || requestVersion != _formVersion) return;
    setState(() {
      challenge = result;
      internetKey.clear();
      step = _LoginStep.key;
    });
  }

  Future<void> _login() async {
    final current = challenge;
    if (current == null) {
      _backToIdentity();
      return;
    }

    if (internetKey.text.length != 6) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Ingresa tu clave de 6 digitos')),
      );
      return;
    }

    final requestVersion = ++_formVersion;
    final ok = await ref
        .read(authControllerProvider.notifier)
        .login(challenge: current, password: internetKey.text.trim());

    if (!mounted || requestVersion != _formVersion) return;
    if (ok) {
      context.go('/home');
    } else {
      _showCurrentError('Clave o datos invalidos');
    }
  }

  void _showCurrentError(String fallback) {
    final error = ref
        .read(authControllerProvider)
        .whenOrNull(error: (error, _) => error.toString());
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(error?.isNotEmpty == true ? error! : fallback)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(authControllerProvider);
    final screenHeight = MediaQuery.sizeOf(context).height;
    final compact = screenHeight < 760;
    final tight = screenHeight < 690;
    final headerHeight = tight ? 300.0 : (compact ? 330.0 : 370.0);

    return Scaffold(
      resizeToAvoidBottomInset: true,
      backgroundColor: AppColors.surface,
      body: Stack(
        children: [
          _BlueHeader(height: headerHeight, compact: compact),
          SafeArea(
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
                  child: Row(
                    children: [
                      if (step == _LoginStep.key)
                        IconButton(
                          onPressed: _backToIdentity,
                          icon: const Icon(
                            Icons.arrow_back_rounded,
                            color: Colors.white,
                          ),
                        )
                      else
                        const Spacer(),
                      const Spacer(),
                      Stack(
                        children: [
                          const Icon(
                            Icons.notifications_none_rounded,
                            color: Colors.white,
                            size: 26,
                          ),
                          Positioned(
                            right: 0,
                            top: 0,
                            child: Container(
                              width: 8,
                              height: 8,
                              decoration: const BoxDecoration(
                                color: AppColors.accent,
                                shape: BoxShape.circle,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 6),
                Image.asset(
                  'assets/images/logo/logo.png',
                  width: compact ? 112 : 132,
                  fit: BoxFit.contain,
                ),
                const SizedBox(height: 4),
                Text(
                  step == _LoginStep.identity ? 'Hola!' : 'Clave de internet',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                Text(
                  step == _LoginStep.identity
                      ? 'Valida tus datos para continuar'
                      : 'Ingresa solo tu clave de 6 digitos',
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: compact ? 12 : 13,
                  ),
                ),
                Expanded(
                  child: ListView(
                    padding: EdgeInsets.zero,
                    children: [
                      SizedBox(height: tight ? 8 : (compact ? 10 : 16)),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 14),
                        child: step == _LoginStep.identity || challenge == null
                            ? _IdentityCard(
                                compact: compact,
                                selectedTab: selectedTab,
                                selectedDocType: selectedDocType,
                                isCompany: isCompany,
                                documentNumber: documentNumber,
                                cardNumber: cardNumber,
                                documentNumberError: documentNumberError,
                                cardNumberError: cardNumberError,
                                rememberUser: rememberUser,
                                loading: state.isLoading,
                                onTabChanged: _changeTab,
                                onDocTypePressed: _showDocTypeSheet,
                                onDocumentChanged: (value) {
                                  _cancelPendingAuth();
                                  final requiredLength =
                                      selectedDocType == 'RUC'
                                      ? 11
                                      : selectedDocType == 'DNI'
                                      ? 8
                                      : 12;
                                  if (documentNumberError &&
                                      value.length == requiredLength) {
                                    setState(() => documentNumberError = false);
                                  }
                                },
                                onCardChanged: (value) {
                                  _cancelPendingAuth();
                                  if (cardNumberError &&
                                      _onlyDigits(value).length == 16) {
                                    setState(() => cardNumberError = false);
                                  }
                                },
                                onRememberChanged: (value) =>
                                    setState(() => rememberUser = value),
                                onContinue: _continueToKey,
                              )
                            : _KeyCard(
                                compact: compact,
                                challenge: challenge!,
                                internetKey: internetKey,
                                obscureKey: obscureKey,
                                loading: state.isLoading,
                                onToggleObscure: () =>
                                    setState(() => obscureKey = !obscureKey),
                                onForgotKey: _showForgotSheet,
                                onLogin: _login,
                                onChangeIdentity: _backToIdentity,
                              ),
                      ),
                      SizedBox(height: step == _LoginStep.identity ? 92 : 16),
                    ],
                  ),
                ),
              ],
            ),
          ),
          if (step == _LoginStep.identity)
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: SafeArea(
                top: false,
                child: Container(
                  padding: const EdgeInsets.only(top: 12, bottom: 12),
                  decoration: BoxDecoration(
                    color: AppColors.surface.withOpacity(.96),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(.06),
                        blurRadius: 18,
                        offset: const Offset(0, -8),
                      ),
                    ],
                  ),
                  child: _BottomLinks(
                    compact: compact,
                    onPromo: () => _showShortcutSheet('Promociones', [
                      const _ShortcutOption(
                        Icons.percent_rounded,
                        'Descuentos activos',
                      ),
                      const _ShortcutOption(
                        Icons.credit_card_rounded,
                        'Cashback en compras',
                      ),
                      const _ShortcutOption(
                        Icons.local_offer_rounded,
                        'Cuotas sin intereses',
                      ),
                    ]),
                    onHelp: () => _showShortcutSheet('Ayuda', [
                      const _ShortcutOption(
                        Icons.help_outline_rounded,
                        'Preguntas frecuentes',
                      ),
                      const _ShortcutOption(
                        Icons.bug_report_outlined,
                        'Reportar un problema',
                      ),
                      const _ShortcutOption(
                        Icons.play_circle_outline_rounded,
                        'Tutoriales',
                      ),
                    ]),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _BlueHeader extends StatelessWidget {
  final double height;
  final bool compact;

  const _BlueHeader({required this.height, required this.compact});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: height,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.primaryDark,
            AppColors.primaryDeep,
            AppColors.primaryLight,
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Stack(
        children: [
          _MachuPicchuBackdrop(compact: compact),
          const _HeaderShade(),
          Positioned(
            left: -60,
            top: compact ? 60 : 80,
            child: _BlurCircle(size: compact ? 160 : 200),
          ),
          Positioned(
            right: -70,
            top: compact ? 80 : 100,
            child: _BlurCircle(size: compact ? 190 : 230),
          ),
        ],
      ),
    );
  }
}

class _MachuPicchuBackdrop extends StatelessWidget {
  final bool compact;

  const _MachuPicchuBackdrop({required this.compact});

  @override
  Widget build(BuildContext context) {
    return Positioned.fill(
      child: IgnorePointer(
        child: Opacity(
          opacity: compact ? .22 : .26,
          child: Image.asset(
            'assets/images/logo/FONDO.png',
            fit: BoxFit.contain,
            width: double.infinity,
            height: double.infinity,
          ),
        ),
      ),
    );
  }
}

class _HeaderShade extends StatelessWidget {
  const _HeaderShade();

  @override
  Widget build(BuildContext context) {
    return Positioned.fill(
      child: IgnorePointer(
        child: DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                AppColors.primaryDeep.withOpacity(.18),
                AppColors.primaryDeep.withOpacity(.04),
                AppColors.primaryDeep.withOpacity(.20),
              ],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
          ),
        ),
      ),
    );
  }
}

class _BlurCircle extends StatelessWidget {
  final double size;

  const _BlurCircle({required this.size});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(.06),
        shape: BoxShape.circle,
      ),
    );
  }
}

class _City extends StatelessWidget {
  final bool compact;

  const _City({required this.compact});

  @override
  Widget build(BuildContext context) {
    final s = compact ? .82 : 1.0;
    final heights = [
      28.0,
      42.0,
      35.0,
      55.0,
      40.0,
      60.0,
      35.0,
      48.0,
      30.0,
      55.0,
      42.0,
      50.0,
      38.0,
      58.0,
      44.0,
    ];

    return SizedBox(
      height: 90 * s,
      child: Stack(
        alignment: Alignment.bottomCenter,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: List.generate(
              heights.length,
              (index) => Container(
                width: 14 * s,
                height: heights[index] * s,
                margin: EdgeInsets.symmetric(horizontal: 3 * s),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(.15),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
          ),
          Container(
            width: 120 * s,
            height: 40 * s,
            decoration: BoxDecoration(
              color: AppColors.primary,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.white24),
            ),
            alignment: Alignment.center,
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: 16 * s),
              child: Image.asset(
                'assets/images/logo/logo.png',
                fit: BoxFit.contain,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _IdentityCard extends StatelessWidget {
  final bool compact;
  final int selectedTab;
  final String selectedDocType;
  final bool isCompany;
  final TextEditingController documentNumber;
  final TextEditingController cardNumber;
  final bool documentNumberError;
  final bool cardNumberError;
  final bool rememberUser;
  final bool loading;
  final ValueChanged<int> onTabChanged;
  final VoidCallback onDocTypePressed;
  final ValueChanged<String> onDocumentChanged;
  final ValueChanged<String> onCardChanged;
  final ValueChanged<bool> onRememberChanged;
  final VoidCallback onContinue;

  const _IdentityCard({
    required this.compact,
    required this.selectedTab,
    required this.selectedDocType,
    required this.isCompany,
    required this.documentNumber,
    required this.cardNumber,
    required this.documentNumberError,
    required this.cardNumberError,
    required this.rememberUser,
    required this.loading,
    required this.onTabChanged,
    required this.onDocTypePressed,
    required this.onDocumentChanged,
    required this.onCardChanged,
    required this.onRememberChanged,
    required this.onContinue,
  });

  @override
  Widget build(BuildContext context) {
    final documentMaxLength = selectedDocType == 'RUC'
        ? 11
        : selectedDocType == 'DNI'
        ? 8
        : 12;

    return _AuthCard(
      compact: compact,
      child: Column(
        children: [
          Row(
            children: [
              _TabItem(
                compact: compact,
                title: 'Personas',
                active: selectedTab == 0,
                onTap: () => onTabChanged(0),
              ),
              _TabItem(
                compact: compact,
                title: 'Empresas',
                active: selectedTab == 1,
                onTap: () => onTabChanged(1),
              ),
            ],
          ),
          SizedBox(height: compact ? 16 : 20),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              SizedBox(
                width: 98,
                child: Column(
                  children: [
                    const _InputLabel('Tipo'),
                    const SizedBox(height: 4),
                    _DocTypeInlineField(
                      compact: compact,
                      value: selectedDocType,
                      locked: isCompany,
                      onTap: onDocTypePressed,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  children: [
                    const _InputLabel('Nro. documento'),
                    const SizedBox(height: 4),
                    _BankTextField(
                      compact: compact,
                      controller: documentNumber,
                      hintText: selectedDocType == 'RUC'
                          ? 'Ingresa RUC'
                          : 'Ingresa documento',
                      icon: Icons.badge_outlined,
                      keyboardType: TextInputType.number,
                      maxLength: documentMaxLength,
                      hasError: documentNumberError,
                      onChanged: onDocumentChanged,
                      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    ),
                  ],
                ),
              ),
            ],
          ),
          SizedBox(height: compact ? 12 : 16),
          const _InputLabel('Numero de tarjeta'),
          const SizedBox(height: 4),
          _BankTextField(
            compact: compact,
            controller: cardNumber,
            hintText: '0000 0000 0000 0000',
            icon: Icons.credit_card_rounded,
            keyboardType: TextInputType.number,
              maxLength: 19,
            hasError: cardNumberError,
            onChanged: onCardChanged,
            inputFormatters: [_CardNumberInputFormatter()],
          ),
          SizedBox(height: compact ? 12 : 16),
          Row(
            children: [
              SizedBox(
                width: compact ? 40 : 44,
                height: compact ? 28 : 30,
                child: FittedBox(
                  fit: BoxFit.contain,
                  child: Switch(
                    value: rememberUser,
                    onChanged: onRememberChanged,
                    activeColor: AppColors.primary,
                  ),
                ),
              ),
              const SizedBox(width: 4),
              const Text(
                'Recordar datos',
                style: TextStyle(
                  color: AppColors.text,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          SizedBox(height: compact ? 12 : 16),
          _PrimaryActionButton(
            compact: compact,
            loading: loading,
            label: 'Continuar',
            onPressed: onContinue,
          ),
        ],
      ),
    );
  }
}

class _KeyCard extends StatelessWidget {
  final bool compact;
  final LoginChallenge challenge;
  final TextEditingController internetKey;
  final bool obscureKey;
  final bool loading;
  final VoidCallback onToggleObscure;
  final VoidCallback onForgotKey;
  final VoidCallback onLogin;
  final VoidCallback onChangeIdentity;

  const _KeyCard({
    required this.compact,
    required this.challenge,
    required this.internetKey,
    required this.obscureKey,
    required this.loading,
    required this.onToggleObscure,
    required this.onForgotKey,
    required this.onLogin,
    required this.onChangeIdentity,
  });

  @override
  Widget build(BuildContext context) {
    return _AuthCard(
      compact: compact,
      child: Column(
        children: [
          Container(
            width: double.infinity,
            padding: EdgeInsets.all(compact ? 12 : 14),
            decoration: BoxDecoration(
              color: AppColors.primarySoft,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.credit_card_rounded,
                  color: AppColors.primary,
                  size: 30,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        challenge.maskedCard,
                        style: const TextStyle(
                          color: AppColors.text,
                          fontSize: 16,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        '${challenge.documentType} ${challenge.documentNumber}',
                        style: const TextStyle(
                          color: AppColors.textMuted,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
                TextButton(
                  onPressed: onChangeIdentity,
                  child: const Text(
                    'Cambiar',
                    style: TextStyle(fontWeight: FontWeight.w800),
                  ),
                ),
              ],
            ),
          ),
          SizedBox(height: compact ? 16 : 20),
          const _InputLabel('Clave de internet'),
          const SizedBox(height: 4),
          _BankTextField(
            compact: compact,
            controller: internetKey,
            hintText: 'Ingresa 6 digitos',
            icon: Icons.lock_outline_rounded,
            obscureText: obscureKey,
            keyboardType: TextInputType.number,
            maxLength: 6,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            suffixIcon: IconButton(
              onPressed: onToggleObscure,
              icon: Icon(
                obscureKey
                    ? Icons.visibility_outlined
                    : Icons.visibility_off_outlined,
                color: AppColors.textMuted,
              ),
            ),
          ),
          SizedBox(height: compact ? 10 : 14),
          Align(
            alignment: Alignment.centerRight,
            child: TextButton(
              onPressed: onForgotKey,
              child: const Text(
                'Olvidaste tu clave?',
                style: TextStyle(
                  color: AppColors.primary,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ),
          SizedBox(height: compact ? 8 : 12),
          _PrimaryActionButton(
            compact: compact,
            loading: loading,
            label: 'Ingresar',
            onPressed: onLogin,
          ),
        ],
      ),
    );
  }
}

class _AuthCard extends StatelessWidget {
  final bool compact;
  final Widget child;

  const _AuthCard({required this.compact, required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.fromLTRB(
        18,
        compact ? 16 : 20,
        18,
        compact ? 18 : 22,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(.08),
            blurRadius: 24,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: child,
    );
  }
}

class _PrimaryActionButton extends StatelessWidget {
  final bool compact;
  final bool loading;
  final String label;
  final VoidCallback onPressed;

  const _PrimaryActionButton({
    required this.compact,
    required this.loading,
    required this.label,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: compact ? 50 : 54,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: AppColors.primary,
          borderRadius: BorderRadius.circular(10),
        ),
        child: ElevatedButton(
          onPressed: loading ? null : onPressed,
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.transparent,
            disabledBackgroundColor: Colors.transparent,
            shadowColor: Colors.transparent,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
          child: loading
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2.2,
                    color: Colors.white,
                  ),
                )
              : Text(
                  label,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 17,
                    fontWeight: FontWeight.w800,
                  ),
                ),
        ),
      ),
    );
  }
}

class _DocTypeInlineField extends StatelessWidget {
  final bool compact;
  final String value;
  final bool locked;
  final VoidCallback onTap;

  const _DocTypeInlineField({
    required this.compact,
    required this.value,
    required this.locked,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: locked ? null : onTap,
      child: Container(
        height: compact ? 42 : 46,
        decoration: const BoxDecoration(
          border: Border(bottom: BorderSide(color: AppColors.line)),
        ),
        child: Row(
          children: [
            Expanded(
              child: Text(
                value,
                style: TextStyle(
                  color: AppColors.text,
                  fontSize: compact ? 15 : 16,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
            Icon(
              locked ? Icons.lock_outline_rounded : Icons.expand_more_rounded,
              color: AppColors.textMuted,
              size: compact ? 20 : 22,
            ),
          ],
        ),
      ),
    );
  }
}

class _BottomLinks extends StatelessWidget {
  final bool compact;
  final VoidCallback onPromo;
  final VoidCallback onHelp;

  const _BottomLinks({
    required this.compact,
    required this.onPromo,
    required this.onHelp,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: compact ? 24 : 36),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _BottomLink(
            compact: compact,
            icon: Icons.percent_rounded,
            text: 'Promociones',
            onTap: onPromo,
          ),
          const SizedBox(
            height: 26,
            child: VerticalDivider(
              color: Color(0xFFD7DEE9),
              width: 28,
              thickness: 1,
            ),
          ),
          _BottomLink(
            compact: compact,
            icon: Icons.help_outline_rounded,
            text: 'Ayuda',
            onTap: onHelp,
          ),
        ],
      ),
    );
  }
}

class _BottomLink extends StatelessWidget {
  final bool compact;
  final IconData icon;
  final String text;
  final VoidCallback onTap;

  const _BottomLink({
    required this.compact,
    required this.icon,
    required this.text,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        child: Row(
          children: [
            Icon(icon, color: AppColors.primaryDeep, size: compact ? 20 : 23),
            const SizedBox(width: 6),
            Text(
              text,
              style: TextStyle(
                color: AppColors.primaryDeep,
                fontWeight: FontWeight.w800,
                fontSize: compact ? 11 : 12,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TabItem extends StatelessWidget {
  final bool compact;
  final String title;
  final bool active;
  final VoidCallback onTap;

  const _TabItem({
    required this.compact,
    required this.title,
    required this.active,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: InkWell(
        borderRadius: BorderRadius.circular(8),
        onTap: onTap,
        child: Column(
          children: [
            Text(
              title,
              style: TextStyle(
                color: active ? AppColors.primary : AppColors.textMuted,
                fontWeight: FontWeight.w900,
                fontSize: compact ? 15 : 16,
              ),
            ),
            SizedBox(height: compact ? 10 : 12),
            AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              height: active ? 3 : 1,
              decoration: BoxDecoration(
                color: active ? AppColors.primary : AppColors.line,
                borderRadius: BorderRadius.circular(20),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _InputLabel extends StatelessWidget {
  final String text;

  const _InputLabel(this.text);

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Text(
        text,
        style: const TextStyle(
          color: AppColors.text,
          fontSize: 13,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _BankTextField extends StatelessWidget {
  final bool compact;
  final TextEditingController controller;
  final String hintText;
  final IconData icon;
  final bool obscureText;
  final TextInputType? keyboardType;
  final int? maxLength;
  final List<TextInputFormatter>? inputFormatters;
  final Widget? suffixIcon;
  final bool hasError;
  final ValueChanged<String>? onChanged;

  const _BankTextField({
    required this.compact,
    required this.controller,
    required this.hintText,
    required this.icon,
    this.obscureText = false,
    this.keyboardType,
    this.maxLength,
    this.inputFormatters,
    this.suffixIcon,
    this.hasError = false,
    this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final accentColor = hasError ? AppColors.danger : AppColors.primary;
    final idleColor = hasError ? AppColors.danger : AppColors.line;
    final iconColor = hasError ? AppColors.danger : AppColors.textMuted;

    return TextField(
      controller: controller,
      obscureText: obscureText,
      keyboardType: keyboardType,
      maxLength: maxLength,
      inputFormatters: inputFormatters,
      onChanged: onChanged,
      textInputAction: TextInputAction.done,
      style: const TextStyle(
        color: AppColors.text,
        fontSize: 16,
        fontWeight: FontWeight.w600,
      ),
      decoration: InputDecoration(
        isDense: compact,
        counterText: '',
        contentPadding: EdgeInsets.only(
          top: compact ? 8 : 10,
          bottom: compact ? 8 : 10,
        ),
        prefixIcon: Icon(icon, color: iconColor, size: compact ? 23 : 26),
        suffixIcon: suffixIcon,
        hintText: hintText,
        hintStyle: const TextStyle(
          color: AppColors.textMuted,
          fontSize: 14,
          fontWeight: FontWeight.w500,
        ),
        enabledBorder: UnderlineInputBorder(
          borderSide: BorderSide(color: idleColor, width: hasError ? 1.4 : 1),
        ),
        focusedBorder: UnderlineInputBorder(
          borderSide: BorderSide(color: accentColor, width: 1.4),
        ),
      ),
    );
  }
}

String _onlyDigits(String value) {
  return value.replaceAll(RegExp(r'\D'), '');
}

String _formatCard(String value) {
  final digits = _onlyDigits(value);
  final limitedDigits = digits.length > 16 ? digits.substring(0, 16) : digits;
  final buffer = StringBuffer();

  for (var index = 0; index < limitedDigits.length; index++) {
    if (index > 0 && index % 4 == 0) {
      buffer.write(' ');
    }
    buffer.write(limitedDigits[index]);
  }

  return buffer.toString();
}

class _CardNumberInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final digits = _onlyDigits(newValue.text);
    final limitedDigits = digits.length > 16 ? digits.substring(0, 16) : digits;
    final buffer = StringBuffer();

    for (var index = 0; index < limitedDigits.length; index++) {
      if (index > 0 && index % 4 == 0) {
        buffer.write(' ');
      }
      buffer.write(limitedDigits[index]);
    }

    final formatted = buffer.toString();
    return TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: formatted.length),
    );
  }
}

class _DocTypeSheet extends StatelessWidget {
  final String current;
  final ValueChanged<String> onSelected;

  const _DocTypeSheet({required this.current, required this.onSelected});

  @override
  Widget build(BuildContext context) {
    const types = ['DNI', 'Carnet de extranjeria', 'Pasaporte'];
    const icons = [
      Icons.badge_outlined,
      Icons.card_membership_outlined,
      Icons.menu_book_outlined,
    ];

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Tipo de documento',
            style: TextStyle(
              color: AppColors.text,
              fontSize: 17,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            'Selecciona el tipo de documento',
            style: TextStyle(color: AppColors.textMuted, fontSize: 13),
          ),
          const SizedBox(height: 16),
          ...List.generate(
            types.length,
            (index) => ListTile(
              contentPadding: EdgeInsets.zero,
              leading: Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: AppColors.primarySoft,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icons[index], color: AppColors.primary, size: 22),
              ),
              title: Text(
                types[index],
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                  color: AppColors.text,
                  fontSize: current == types[index] ? 15 : 14,
                ),
              ),
              trailing: current == types[index]
                  ? const Icon(Icons.check_rounded, color: AppColors.primary)
                  : null,
              onTap: () => onSelected(types[index]),
            ),
          ),
          const SizedBox(height: 8),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton(
              onPressed: () => Navigator.pop(context),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 14),
                side: const BorderSide(color: AppColors.line),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              child: const Text(
                'Cancelar',
                style: TextStyle(
                  color: AppColors.primary,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ForgotKeySheet extends StatelessWidget {
  const _ForgotKeySheet();

  @override
  Widget build(BuildContext context) {
    final options = [
      (Icons.sms_outlined, 'Por SMS', 'Te enviaremos un codigo a tu celular'),
      (
        Icons.email_outlined,
        'Por correo electronico',
        'Recibiras instrucciones en tu email',
      ),
      (
        Icons.account_balance_rounded,
        'En una agencia YORBANK',
        'Visitanos con tu documento de identidad',
      ),
    ];

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Olvidaste tu clave?',
            style: TextStyle(
              color: AppColors.text,
              fontSize: 17,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            'Elige como recuperarla',
            style: TextStyle(color: AppColors.textMuted, fontSize: 13),
          ),
          const SizedBox(height: 16),
          ...options.map(
            (option) => ListTile(
              contentPadding: EdgeInsets.zero,
              leading: Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: AppColors.primarySoft,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(option.$1, color: AppColors.primary, size: 22),
              ),
              title: Text(
                option.$2,
                style: const TextStyle(
                  fontWeight: FontWeight.w700,
                  color: AppColors.text,
                  fontSize: 14,
                ),
              ),
              subtitle: Text(
                option.$3,
                style: const TextStyle(
                  color: AppColors.textMuted,
                  fontSize: 12,
                ),
              ),
              onTap: () => Navigator.pop(context),
            ),
          ),
          const SizedBox(height: 8),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton(
              onPressed: () => Navigator.pop(context),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 14),
                side: const BorderSide(color: AppColors.line),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              child: const Text(
                'Cancelar',
                style: TextStyle(
                  color: AppColors.primary,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ShortcutOption {
  final IconData icon;
  final String label;

  const _ShortcutOption(this.icon, this.label);
}

class _OptionsSheet extends StatelessWidget {
  final String title;
  final List<_ShortcutOption> options;

  const _OptionsSheet({required this.title, required this.options});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              color: AppColors.text,
              fontSize: 17,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 16),
          ...options.map(
            (option) => ListTile(
              contentPadding: EdgeInsets.zero,
              leading: Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: AppColors.primarySoft,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(option.icon, color: AppColors.primary, size: 22),
              ),
              title: Text(
                option.label,
                style: const TextStyle(
                  fontWeight: FontWeight.w700,
                  color: AppColors.text,
                  fontSize: 14,
                ),
              ),
              trailing: const Icon(
                Icons.chevron_right_rounded,
                color: AppColors.textMuted,
              ),
              onTap: () => Navigator.pop(context),
            ),
          ),
          const SizedBox(height: 8),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton(
              onPressed: () => Navigator.pop(context),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 14),
                side: const BorderSide(color: AppColors.line),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              child: const Text(
                'Cancelar',
                style: TextStyle(
                  color: AppColors.primary,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
