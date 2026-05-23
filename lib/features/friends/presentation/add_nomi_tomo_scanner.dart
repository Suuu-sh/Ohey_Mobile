part of 'add_nomi_tomo_screen.dart';

class NomiTomoQrScannerScreen extends StatefulWidget {
  const NomiTomoQrScannerScreen({super.key});

  @override
  State<NomiTomoQrScannerScreen> createState() => _QrScannerScreenState();
}

class _QrScannerScreenState extends State<NomiTomoQrScannerScreen> {
  final MobileScannerController _controller = MobileScannerController();
  bool _returned = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _onDetect(BarcodeCapture capture) {
    if (_returned) return;
    final code = capture.barcodes.isEmpty
        ? null
        : capture.barcodes.first.rawValue;
    if (code == null || code.isEmpty) return;
    _returned = true;
    Navigator.of(context).pop(code);
  }

  Future<void> _scanFromImage() async {
    if (kIsWeb) {
      NomoToast.show(context, 'Web では画像読み込みからのスキャンは未対応です。');
      return;
    }

    final picker = ImagePicker();
    final image = await picker.pickImage(source: ImageSource.gallery);
    if (image == null || !mounted) return;

    try {
      final barcodes = await _controller.analyzeImage(image.path);
      if (!mounted || _returned) return;
      if (barcodes == null || barcodes.barcodes.isEmpty) {
        NomoToast.show(context, 'QRコードが見つかりませんでした');
        return;
      }
      final code = barcodes.barcodes.first.rawValue;
      if (code == null || code.isEmpty) {
        NomoToast.show(context, 'QRコードが見つかりませんでした');
        return;
      }
      _returned = true;
      Navigator.of(context).pop(code);
    } catch (_) {
      if (!mounted) return;
      NomoToast.show(context, '画像の読み込みに失敗しました');
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    resizeToAvoidBottomInset: false,
    backgroundColor: Colors.black,
    appBar: AppBar(
      backgroundColor: Colors.black,
      foregroundColor: Colors.white,
      title: const Text('QRを読み取る'),
    ),
    body: Stack(
      children: [
        MobileScanner(controller: _controller, onDetect: _onDetect),
        Center(
          child: Container(
            width: 240,
            height: 240,
            decoration: BoxDecoration(
              border: Border.all(color: _ExchangeColors.lime, width: 4),
              borderRadius: BorderRadius.circular(30),
              boxShadow: [
                BoxShadow(
                  color: _ExchangeColors.lime.withValues(alpha: .28),
                  blurRadius: 28,
                ),
              ],
            ),
          ),
        ),
        Positioned(
          bottom: 20,
          left: 20,
          right: 20,
          child: SafeArea(
            top: false,
            child: _MiniPopButton(
              label: '画像から読み取り',
              icon: CupertinoIcons.photo,
              color: _ExchangeColors.teal,
              onTap: _scanFromImage,
            ),
          ),
        ),
      ],
    ),
  );
}
