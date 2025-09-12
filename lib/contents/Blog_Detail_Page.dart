import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:gb_merchant/utils/constants.dart';
import '../widgets/modern_image_slider.dart';
import '../models/slider_model.dart';

class BlogDetailPage extends StatefulWidget {
  final SliderModel slider;
  final List<SliderModel> allSlides;

  const BlogDetailPage({
    Key? key,
    required this.slider,
    required this.allSlides,
  }) : super(key: key);

  @override
  _BlogDetailPageState createState() => _BlogDetailPageState();
}

class _BlogDetailPageState extends State<BlogDetailPage>
    with TickerProviderStateMixin {
  late SliderModel currentSlider;
  late List<SliderModel> allSlides;
  bool isLoadingMore = false;
  int currentIndex = 0;
  late AnimationController _buttonController;
  late Animation<Offset> _buttonAnimation;
  String _slideDirection = 'up';

  late AnimationController _slideController;
  late Animation<Offset> _slideAnimation;

  bool _isShowingNext = false;
  SliderModel? _nextSlider;

  @override
  void initState() {
    super.initState();
    currentSlider = widget.slider;
    allSlides = widget.allSlides;

    currentIndex = allSlides.indexWhere(
      (slide) => slide.id == currentSlider.id,
    );

    _slideController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );

    _buttonController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );

    _buttonAnimation = Tween<Offset>(
      begin: const Offset(0, 0),
      end: const Offset(0, -0.2),
    ).animate(
      CurvedAnimation(parent: _buttonController, curve: Curves.easeInOut),
    );

    _buttonController.repeat(reverse: true);

    _slideAnimation = _createSlideAnimation(direction: 'up');
  }

  Animation<Offset> _createSlideAnimation({required String direction}) {
    final beginOffset =
        direction == 'up' ? const Offset(0, 1.0) : const Offset(0, -1.0);
    return Tween<Offset>(
      begin: beginOffset,
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _slideController, curve: Curves.easeOut));
  }

  @override
  void dispose() {
    _slideController.dispose();
    _buttonController.dispose();
    super.dispose();
  }

  void _loadNextSlide() async {
    if (allSlides.isEmpty || currentIndex >= allSlides.length - 1) return;

    setState(() {
      isLoadingMore = true;
      _isShowingNext = true;
      _nextSlider = allSlides[currentIndex + 1];
      _slideDirection = 'up';
      _slideAnimation = _createSlideAnimation(direction: _slideDirection);
    });

    _slideController.forward(from: 0.0);
    await Future.delayed(const Duration(milliseconds: 600));

    setState(() {
      currentIndex++;
      currentSlider = allSlides[currentIndex];
      isLoadingMore = false;
      _isShowingNext = false;
      _nextSlider = null;
    });
  }

  void _loadPreviousSlide() async {
    if (allSlides.isEmpty || currentIndex <= 0) return;

    setState(() {
      isLoadingMore = true;
      _isShowingNext = true;
      _nextSlider = allSlides[currentIndex - 1];
      _slideDirection = 'down';
      _slideAnimation = _createSlideAnimation(direction: _slideDirection);
    });

    _slideController.forward(from: 0.0);
    await Future.delayed(const Duration(milliseconds: 600));

    setState(() {
      currentIndex--;
      currentSlider = allSlides[currentIndex];
      isLoadingMore = false;
      _isShowingNext = false;
      _nextSlider = null;
    });
  }

  Widget _buildContent(SliderModel slider) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Stack(
          children: [
            ModernImageSlider(imageUrls: slider.imageUrls),
            Positioned(
              right: 25,
              bottom: 55,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 5,
                ),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.5),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '${currentIndex + 1}/${allSlides.length}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 24),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Text(
            slider.title,
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w800,
              color: AppColors.backgroundColor,
              letterSpacing: 0.2,
              height: 1.28,
              fontFamily: 'KhmerFont',
            ),
          ),
        ),
        const SizedBox(height: 20),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Text(
            slider.description,
            style: TextStyle(
              fontSize: 17,
              color: Colors.white.withOpacity(0.9),
              fontWeight: FontWeight.w600,
              height: 1.7,
              fontFamily: 'KhmerFont',
            ),
          ),
        ),
        const SizedBox(height: 30),
      ],
    );
  }

  IconData get _arrowIcon {
    if (currentIndex < allSlides.length - 1) {
      return Icons.arrow_downward;
    } else if (currentIndex > 0) {
      return Icons.arrow_upward;
    } else {
      return Icons.close;
    }
  }

  void _onArrowPressed() {
    if (isLoadingMore) return;

    if (currentIndex < allSlides.length - 1) {
      _loadNextSlide();
    } else if (currentIndex > 0) {
      _loadPreviousSlide();
    }
  }

  @override
  Widget build(BuildContext context) {
    final localeCode = context.locale.languageCode;

    return Dialog(
      insetPadding: EdgeInsets.zero,
      child: SizedBox(
        width: MediaQuery.of(context).size.width,
        height: MediaQuery.of(context).size.height,
        child: Material(
          color: AppColors.primaryColor,
          child: SafeArea(
            child: Column(
              children: [
                AppBar(
                  backgroundColor: Colors.transparent,
                  elevation: 0,
                  leading: IconButton(
                    icon: const Icon(Icons.arrow_back, color: Colors.white),
                    onPressed: () {
                      Navigator.pop(context);
                    },
                  ),
                  title: Text(
                    'blogdetail'.tr(),
                    style: TextStyle(
                      color: Colors.white,
                      fontFamily: localeCode == 'km' ? 'KhmerFont' : null,
                      fontSize: 24,
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Expanded(
                  child: Stack(
                    children: [
                      Transform.translate(
                        offset: Offset(
                          0,
                          _isShowingNext
                              ? -MediaQuery.of(context).size.height * 0.2
                              : 0,
                        ),
                        child: Opacity(
                          opacity: _isShowingNext ? 0.7 : 1.0,
                          child: SingleChildScrollView(
                            child: _buildContent(currentSlider),
                          ),
                        ),
                      ),
                      if (_isShowingNext && _nextSlider != null)
                        SlideTransition(
                          position: _slideAnimation,
                          child: Container(
                            color: AppColors.primaryColor,
                            child: SingleChildScrollView(
                              child: _buildContent(_nextSlider!),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
                if (allSlides.length > 1)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child:
                        isLoadingMore
                            ? CircularProgressIndicator(
                              valueColor: AlwaysStoppedAnimation<Color>(
                                Colors.white,
                              ),
                            )
                            : SlideTransition(
                              position: _buttonAnimation,
                              child: FloatingActionButton(
                                onPressed: _onArrowPressed,
                                backgroundColor: AppColors.primaryColor,
                                child: Icon(_arrowIcon, color: Colors.white),
                              ),
                            ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
