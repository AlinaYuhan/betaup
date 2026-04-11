import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../data/models.dart';

const _backgroundGradient = LinearGradient(
  begin: Alignment.topLeft,
  end: Alignment.bottomRight,
  colors: [
    Color(0xFF09111F),
    Color(0xFF101A2C),
    Color(0xFF071624),
  ],
);

class BetaUpScaffold extends StatelessWidget {
  const BetaUpScaffold({
    required this.title,
    required this.child,
    super.key,
    this.subtitle,
    this.actions = const [],
    this.floatingActionButton,
    this.bottomNavigationBar,
  });

  final String title;
  final String? subtitle;
  final Widget child;
  final List<Widget> actions;
  final Widget? floatingActionButton;
  final Widget? bottomNavigationBar;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: const BoxDecoration(gradient: _backgroundGradient),
      child: Stack(
        children: [
          const Positioned(
            top: -80,
            left: -40,
            child: _GlowOrb(
              color: Color(0x33FF7A18),
              size: 240,
            ),
          ),
          const Positioned(
            top: 120,
            right: -60,
            child: _GlowOrb(
              color: Color(0x337BE0FF),
              size: 220,
            ),
          ),
          Scaffold(
            backgroundColor: Colors.transparent,
            appBar: AppBar(
              titleSpacing: 20,
              title: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title),
                  if (subtitle != null && subtitle!.trim().isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 2),
                      child: Text(
                        subtitle!,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: const Color(0xFF9AA9BE),
                            ),
                      ),
                    ),
                ],
              ),
              actions: actions,
            ),
            body: SafeArea(
              top: false,
              child: child,
            ),
            floatingActionButton: floatingActionButton,
            bottomNavigationBar: bottomNavigationBar,
          ),
        ],
      ),
    );
  }
}

class SplashScreen extends StatelessWidget {
  const SplashScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const BetaUpScaffold(
      title: "BetaUp",
      subtitle: "Connecting to backend",
      child: Center(
        child: LoaderCard(label: "Bootstrapping session"),
      ),
    );
  }
}

class GlassCard extends StatelessWidget {
  const GlassCard({
    required this.child,
    super.key,
    this.padding = const EdgeInsets.all(20),
    this.margin = const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
    this.backgroundColor,
    this.borderColor,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final EdgeInsetsGeometry margin;
  final Color? backgroundColor;
  final Color? borderColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: margin,
      decoration: BoxDecoration(
        color: backgroundColor ?? Colors.white.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(28),
        border: Border.all(
          color: borderColor ?? Colors.white.withValues(alpha: 0.16),
        ),
        boxShadow: const [
          BoxShadow(
            color: Color(0x22000000),
            blurRadius: 24,
            offset: Offset(0, 16),
          ),
        ],
      ),
      child: Padding(
        padding: padding,
        child: child,
      ),
    );
  }
}

class SectionLabel extends StatelessWidget {
  const SectionLabel(this.text, {super.key});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text.toUpperCase(),
      style: Theme.of(context).textTheme.labelMedium?.copyWith(
            color: const Color(0xFF7BE0FF),
            letterSpacing: 1.6,
            fontWeight: FontWeight.w800,
          ),
    );
  }
}

class StatusChip extends StatelessWidget {
  const StatusChip({
    required this.label,
    super.key,
    this.color = const Color(0xFF7BE0FF),
  });

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.16),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withValues(alpha: 0.24)),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontWeight: FontWeight.w800,
          fontSize: 12,
        ),
      ),
    );
  }
}

class MetricTile extends StatelessWidget {
  const MetricTile({
    required this.label,
    required this.value,
    super.key,
    this.helper,
    this.highlight = const Color(0xFFFF7A18),
  });

  final String label;
  final String value;
  final String? helper;
  final Color highlight;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        color: Colors.white.withValues(alpha: 0.04),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          StatusChip(label: label, color: highlight),
          const SizedBox(height: 14),
          Text(
            value,
            style: Theme.of(context).textTheme.headlineMedium,
          ),
          if (helper != null && helper!.trim().isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(helper!, style: Theme.of(context).textTheme.bodyMedium),
          ],
        ],
      ),
    );
  }
}

class LoaderCard extends StatelessWidget {
  const LoaderCard({
    required this.label,
    super.key,
  });

  final String label;

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(
            width: 28,
            height: 28,
            child: CircularProgressIndicator(strokeWidth: 2.6),
          ),
          const SizedBox(height: 16),
          Text(label, style: Theme.of(context).textTheme.titleMedium),
        ],
      ),
    );
  }
}

class ErrorCard extends StatelessWidget {
  const ErrorCard({
    required this.message,
    super.key,
    this.onRetry,
  });

  final String message;
  final Future<void> Function()? onRetry;

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      backgroundColor: const Color(0x33261117),
      borderColor: const Color(0x66FF7B7B),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const StatusChip(
            label: "Error",
            color: Color(0xFFFF7B7B),
          ),
          const SizedBox(height: 14),
          Text(
            message,
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: const Color(0xFFF7EDF0),
                ),
          ),
          if (onRetry != null) ...[
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: () => onRetry!.call(),
              icon: const Icon(Icons.refresh_rounded),
              label: const Text("Retry"),
            ),
          ],
        ],
      ),
    );
  }
}

class EmptyCard extends StatelessWidget {
  const EmptyCard({
    required this.title,
    required this.message,
    super.key,
  });

  final String title;
  final String message;

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SectionLabel(title),
          const SizedBox(height: 12),
          Text(title, style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 8),
          Text(message, style: Theme.of(context).textTheme.bodyMedium),
        ],
      ),
    );
  }
}

class PagingControls extends StatelessWidget {
  const PagingControls({
    required this.page,
    required this.totalPages,
    required this.hasNext,
    required this.hasPrevious,
    required this.onChanged,
    super.key,
  });

  final int page;
  final int totalPages;
  final bool hasNext;
  final bool hasPrevious;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          Expanded(
            child: OutlinedButton(
              onPressed: hasPrevious ? () => onChanged(page - 1) : null,
              child: const Text("Previous"),
            ),
          ),
          const SizedBox(width: 12),
          Text(
            "Page ${page + 1}${totalPages > 0 ? " / $totalPages" : ""}",
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: ElevatedButton(
              onPressed: hasNext ? () => onChanged(page + 1) : null,
              child: const Text("Next"),
            ),
          ),
        ],
      ),
    );
  }
}

class MiniBarChart extends StatelessWidget {
  const MiniBarChart({
    required this.points,
    super.key,
  });

  final List<DashboardChartPoint> points;

  @override
  Widget build(BuildContext context) {
    if (points.isEmpty) {
      return const SizedBox.shrink();
    }

    final maxValue = points
        .map((point) => point.value)
        .fold<int>(0, (current, value) => value > current ? value : current);
    final theme = Theme.of(context);

    return SizedBox(
      height: 180,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: points.map((point) {
          final fraction = maxValue == 0 ? 0.0 : point.value / maxValue;
          return Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Text(
                    "${point.value}",
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: const Color(0xFFE8EFFA),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Expanded(
                    child: Align(
                      alignment: Alignment.bottomCenter,
                      child: FractionallySizedBox(
                        heightFactor: fraction.clamp(0.06, 1.0),
                        child: Container(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(18),
                            gradient: const LinearGradient(
                              begin: Alignment.bottomCenter,
                              end: Alignment.topCenter,
                              colors: [
                                Color(0xFFFF7A18),
                                Color(0xFF7BE0FF),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    point.label,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.center,
                    style: theme.textTheme.bodySmall,
                  ),
                ],
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}

class SummaryList extends StatelessWidget {
  const SummaryList({
    required this.items,
    super.key,
    this.valueSuffix = "",
  });

  final List<DashboardBreakdownItem> items;
  final String valueSuffix;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: items.map((item) {
        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(item.label,
                        style: Theme.of(context).textTheme.titleMedium),
                    const SizedBox(height: 4),
                    if (item.helper.trim().isNotEmpty)
                      Text(item.helper,
                          style: Theme.of(context).textTheme.bodySmall),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Text(
                "${item.value}$valueSuffix",
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: const Color(0xFFFFB26D),
                    ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }
}

class ActivityFeed extends StatelessWidget {
  const ActivityFeed({
    required this.items,
    super.key,
  });

  final List<DashboardActivity> items;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: items.map((item) {
        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.04),
            borderRadius: BorderRadius.circular(22),
            border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 12,
                height: 12,
                margin: const EdgeInsets.only(top: 6),
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    colors: [Color(0xFFFF7A18), Color(0xFF7BE0FF)],
                  ),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(item.title,
                        style: Theme.of(context).textTheme.titleMedium),
                    if (item.subtitle.trim().isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(item.subtitle,
                          style: Theme.of(context).textTheme.bodyMedium),
                    ],
                    if (item.meta.trim().isNotEmpty) ...[
                      const SizedBox(height: 8),
                      Text(
                        item.meta.toUpperCase(),
                        style:
                            Theme.of(context).textTheme.labelMedium?.copyWith(
                                  color: const Color(0xFF93A6C2),
                                  letterSpacing: 1.2,
                                ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }
}

class _GlowOrb extends StatelessWidget {
  const _GlowOrb({
    required this.color,
    required this.size,
  });

  final Color color;
  final double size;

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: color,
              blurRadius: 90,
              spreadRadius: 20,
            ),
          ],
        ),
      ),
    );
  }
}

void showAppSnackBar(ScaffoldMessengerState messenger, String message) {
  messenger.showSnackBar(
    SnackBar(
      backgroundColor: const Color(0xFF132238),
      content: Text(message),
    ),
  );
}

String formatShortDate(DateTime? date) {
  if (date == null) {
    return "--";
  }
  return DateFormat("yyyy-MM-dd").format(date);
}

String formatReadableDate(DateTime? date) {
  if (date == null) {
    return "--";
  }
  return DateFormat("MMM d, yyyy").format(date);
}

String formatReadableDateTime(DateTime? dateTime) {
  if (dateTime == null) {
    return "--";
  }
  return DateFormat("MMM d, yyyy HH:mm").format(dateTime);
}

Color statusColor(ClimbStatus status) {
  switch (status) {
    case ClimbStatus.completed:
      return const Color(0xFF5ED9A6);
    case ClimbStatus.attempted:
      return const Color(0xFFFFB26D);
  }
}

Color resultColor(ClimbResult result) {
  switch (result) {
    case ClimbResult.flash:
      return const Color(0xFFFFD700); // gold
    case ClimbResult.send:
      return const Color(0xFF5ED9A6); // green
    case ClimbResult.attempt:
      return const Color(0xFFFFB26D); // orange
  }
}

List<String> sortParts(String value, String fallback) {
  final parts = value.split(":");
  if (parts.length == 2 && parts.first.isNotEmpty && parts.last.isNotEmpty) {
    return parts;
  }
  return fallback.split(":");
}
