import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';

/// Loading skeleton placeholder displaying columns and cards during state loading.
class KanbanLoadingSkeleton extends StatefulWidget {
  const KanbanLoadingSkeleton({super.key});

  @override
  State<KanbanLoadingSkeleton> createState() => _KanbanLoadingSkeletonState();
}

class _KanbanLoadingSkeletonState extends State<KanbanLoadingSkeleton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _opacityAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    )..repeat(reverse: true);

    _opacityAnimation = Tween<double>(begin: 0.35, end: 0.75).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _opacityAnimation,
      builder: (context, child) {
        return Opacity(
          opacity: _opacityAnimation.value,
          child: LayoutBuilder(
            builder: (context, constraints) {
              const columnCount = 5;
              final columnWidth = constraints.maxWidth >= 1400
                  ? (constraints.maxWidth - 32 - (4 * 16)) / columnCount
                  : 300.0;

              return SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: List.generate(columnCount, (index) {
                    return Container(
                      width: columnWidth,
                      margin: EdgeInsets.only(
                        right: index < columnCount - 1 ? 16 : 0,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.slate900,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: AppColors.slate700),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          // Header skeleton
                          Container(
                            height: 48,
                            padding: const EdgeInsets.symmetric(horizontal: 14),
                            decoration: const BoxDecoration(
                              color: AppColors.slate850,
                              borderRadius: BorderRadius.only(
                                topLeft: Radius.circular(14),
                                topRight: Radius.circular(14),
                              ),
                            ),
                            child: Row(
                              children: [
                                Container(
                                  width: 10,
                                  height: 10,
                                  decoration: const BoxDecoration(
                                    color: AppColors.slate700,
                                    shape: BoxShape.circle,
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Container(
                                  width: 80,
                                  height: 14,
                                  decoration: BoxDecoration(
                                    color: AppColors.slate700,
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                ),
                                const Spacer(),
                                Container(
                                  width: 24,
                                  height: 18,
                                  decoration: BoxDecoration(
                                    color: AppColors.slate800,
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const Divider(
                            height: 1,
                            thickness: 1,
                            color: AppColors.slate700,
                          ),
                          // Card skeletons
                          Padding(
                            padding: const EdgeInsets.all(12),
                            child: Column(
                              children: List.generate(3, (cardIndex) {
                                return Container(
                                  margin: const EdgeInsets.only(bottom: 12),
                                  padding: const EdgeInsets.all(14),
                                  decoration: BoxDecoration(
                                    color: AppColors.slate800,
                                    borderRadius: BorderRadius.circular(12),
                                    border:
                                        Border.all(color: AppColors.slate700),
                                  ),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Container(
                                        width: 50,
                                        height: 12,
                                        decoration: BoxDecoration(
                                          color: AppColors.slate700,
                                          borderRadius:
                                              BorderRadius.circular(4),
                                        ),
                                      ),
                                      const SizedBox(height: 10),
                                      Container(
                                        width: double.infinity,
                                        height: 16,
                                        decoration: BoxDecoration(
                                          color: AppColors.slate700,
                                          borderRadius:
                                              BorderRadius.circular(4),
                                        ),
                                      ),
                                      const SizedBox(height: 8),
                                      Container(
                                        width: 140,
                                        height: 12,
                                        decoration: BoxDecoration(
                                          color: AppColors.slate700,
                                          borderRadius:
                                              BorderRadius.circular(4),
                                        ),
                                      ),
                                      const SizedBox(height: 12),
                                      Row(
                                        children: [
                                          Container(
                                            width: 60,
                                            height: 18,
                                            decoration: BoxDecoration(
                                              color: AppColors.slate850,
                                              borderRadius:
                                                  BorderRadius.circular(6),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                );
                              }),
                            ),
                          ),
                        ],
                      ),
                    );
                  }),
                ),
              );
            },
          ),
        );
      },
    );
  }
}
