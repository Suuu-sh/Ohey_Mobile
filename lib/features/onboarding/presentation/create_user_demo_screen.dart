part of 'create_user_dialog.dart';

class OheyDemoScreen extends StatefulWidget {
  const OheyDemoScreen({super.key});

  @override
  State<OheyDemoScreen> createState() => _OheyDemoScreenState();
}

class _OheyDemoScreenState extends State<OheyDemoScreen> {
  final _controller = PageController();
  int _page = 0;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final slides = _demoSlides;
    return Scaffold(
      resizeToAvoidBottomInset: false,
      backgroundColor: AppColors.darkBackground,
      body: Stack(
        children: [
          Positioned.fill(
            child: PageView.builder(
              controller: _controller,
              onPageChanged: (index) => setState(() => _page = index),
              itemCount: slides.length,
              itemBuilder: (context, index) => _DemoSlide(slide: slides[index]),
            ),
          ),
          SafeArea(
            child: Align(
              alignment: Alignment.topRight,
              child: Padding(
                padding: const EdgeInsets.only(top: 10, right: 18),
                child: IconButton(
                  onPressed: () => Navigator.of(context).pop(),
                  icon: const OheyGeneratedIcon(
                    CupertinoIcons.xmark,
                    color: Colors.white,
                    size: 28,
                  ),
                ),
              ),
            ),
          ),
          SafeArea(
            child: Align(
              alignment: Alignment.bottomCenter,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(28, 0, 28, 22),
                child: Row(
                  children: [
                    _DemoDots(count: slides.length, selectedIndex: _page),
                    const Spacer(),
                    TextButton(
                      onPressed: () => Navigator.of(context).pop(),
                      child: const Text('閉じる'),
                    ),
                    const SizedBox(width: 8),
                    GestureDetector(
                      onTap: () {
                        if (_page < slides.length - 1) {
                          _controller.nextPage(
                            duration: const Duration(milliseconds: 260),
                            curve: Curves.easeOutCubic,
                          );
                          return;
                        }
                        Navigator.of(context).pop();
                      },
                      child: Container(
                        width: 58,
                        height: 58,
                        decoration: const BoxDecoration(
                          color: Color(0xFF12C9A4),
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: Color(0xFF079078),
                              offset: Offset(0, 6),
                              blurRadius: 0,
                            ),
                          ],
                        ),
                        child: Center(
                          child: OheyPopIcon(
                            icon: _page == slides.length - 1
                                ? CupertinoIcons.checkmark
                                : CupertinoIcons.arrow_right,
                            color: Colors.white,
                            foregroundColor: Colors.white,
                            showBubble: false,
                            size: 30,
                            iconSize: 28,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
