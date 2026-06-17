import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:image_picker/image_picker.dart';

import '../../../core/navigation/app_page_route.dart';
import '../../../core/services/api_client.dart';
import '../../../core/theme/app_theme.dart';
import '../models/food_item.dart';
import '../models/recognition_candidate.dart';
import '../services/food_service.dart';
import 'log_portion_screen.dart';

class PhotoRecognizeScreen extends StatefulWidget {
  const PhotoRecognizeScreen({super.key});

  @override
  State<PhotoRecognizeScreen> createState() => _PhotoRecognizeScreenState();
}

class _PhotoRecognizeScreenState extends State<PhotoRecognizeScreen> {
  final _foodService = FoodService();
  final _picker = ImagePicker();

  File? _image;
  bool _recognizing = false;
  List<RecognitionCandidate> _candidates = [];
  String? _error;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _pickImage(ImageSource.camera));
  }

  Future<void> _pickImage(ImageSource source) async {
    final picked = await _picker.pickImage(source: source, imageQuality: 80);
    if (picked == null) {
      if (mounted && source == ImageSource.camera && _candidates.isEmpty && _error == null) {
        Navigator.of(context).pop();
      }
      return;
    }

    final file = File(picked.path);
    setState(() {
      _image = file;
      _recognizing = true;
      _candidates = [];
      _error = null;
    });

    try {
      final bytes = await file.readAsBytes();
      final candidates = await _foodService.recognizePhoto(bytes, filename: picked.name);
      if (!mounted) return;
      if (candidates.isEmpty) {
        setState(() {
          _recognizing = false;
          _error = 'No food recognized in this photo. Try a clearer image of a meal.';
        });
      } else {
        setState(() {
          _recognizing = false;
          _candidates = candidates;
        });
      }
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() {
        _recognizing = false;
        _error = e.message;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _recognizing = false;
        _error = 'Failed to recognize food. Please try again.';
      });
    }
  }

  void _selectItem(FoodItem item) {
    Navigator.of(context).pushReplacement(
      AppPageRoute(builder: (_) => LogPortionScreen(foodItem: item)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Photo Recognition'),
        actions: [
          IconButton(
            icon: const Icon(Icons.photo_library_outlined),
            tooltip: 'Pick from gallery',
            onPressed: _recognizing ? null : () => _pickImage(ImageSource.gallery),
          ),
          IconButton(
            icon: const Icon(Icons.camera_alt_outlined),
            tooltip: 'Retake photo',
            onPressed: _recognizing ? null : () => _pickImage(ImageSource.camera),
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            if (_image != null)
              Container(
                height: 200,
                width: double.infinity,
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surfaceContainerHighest,
                ),
                child: Image.file(_image!, fit: BoxFit.cover),
              ),
            Expanded(
              child: _recognizing
                  ? const _RecognizingPlaceholder()
                  : _error != null
                      ? _ErrorState(message: _error!, onRetry: () => _pickImage(ImageSource.camera))
                      : _candidates.isEmpty
                          ? const _EmptyState()
                          : _CandidatesList(candidates: _candidates, onSelect: _selectItem),
            ),
          ],
        ),
      ),
    );
  }
}

class _RecognizingPlaceholder extends StatelessWidget {
  const _RecognizingPlaceholder();

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: 48,
            height: 48,
            child: CircularProgressIndicator(color: colorScheme.primary, strokeWidth: 3),
          ),
          const SizedBox(height: 16),
          Text('Recognizing food…', style: textTheme.titleMedium),
          const SizedBox(height: 6),
          Text(
            'This may take a few seconds.',
            style: textTheme.bodySmall?.copyWith(color: colorScheme.onSurfaceVariant),
          ),
        ],
      ),
    );
  }
}

class _ErrorState extends StatelessWidget {
  const _ErrorState({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.error_outline, size: 48, color: colorScheme.error),
            const SizedBox(height: 12),
            Text(message, style: textTheme.bodyMedium, textAlign: TextAlign.center),
            const SizedBox(height: 20),
            FilledButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.camera_alt),
              label: const Text('Try again'),
            ),
          ],
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Text(
        'Point your camera at a meal to get started.',
        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
        textAlign: TextAlign.center,
      ),
    );
  }
}

class _CandidatesList extends StatelessWidget {
  const _CandidatesList({required this.candidates, required this.onSelect});

  final List<RecognitionCandidate> candidates;
  final void Function(FoodItem) onSelect;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final colorScheme = Theme.of(context).colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
          child: Text(
            '${candidates.length} food${candidates.length == 1 ? '' : 's'} detected — tap to log',
            style: textTheme.titleSmall?.copyWith(color: colorScheme.onSurfaceVariant),
          ),
        ),
        Expanded(
          child: ListView.builder(
            itemCount: candidates.length,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemBuilder: (context, index) {
              final candidate = candidates[index];
              final best = candidate.bestMatch!;
              final pct = (candidate.confidence * 100).round();

              return Card(
                margin: const EdgeInsets.only(bottom: 10),
                child: InkWell(
                  borderRadius: BorderRadius.circular(AppTheme.cardRadius.toDouble()),
                  onTap: () => onSelect(best),
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Row(
                      children: [
                        CircleAvatar(
                          radius: 24,
                          backgroundColor: AppTheme.secondary.withValues(alpha: 0.15),
                          child: const Icon(Icons.restaurant_outlined, color: AppTheme.secondary),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      _capitalize(candidate.label),
                                      style: textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700),
                                    ),
                                  ),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: _confidenceColor(candidate.confidence).withValues(alpha: 0.15),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Text(
                                      '$pct%',
                                      style: textTheme.labelSmall?.copyWith(
                                        color: _confidenceColor(candidate.confidence),
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 4),
                              Text(
                                best.name,
                                style: textTheme.bodySmall?.copyWith(color: colorScheme.onSurfaceVariant),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              Text(
                                '${best.calories.toStringAsFixed(0)} kcal · ${best.servingDescription}',
                                style: textTheme.bodySmall?.copyWith(color: colorScheme.onSurfaceVariant),
                              ),
                              if (candidate.matches.length > 1) ...[
                                const SizedBox(height: 4),
                                Text(
                                  '+${candidate.matches.length - 1} other match${candidate.matches.length == 2 ? '' : 'es'}',
                                  style: textTheme.labelSmall?.copyWith(color: colorScheme.primary),
                                ),
                              ],
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                        const Icon(Icons.chevron_right),
                      ],
                    ),
                  ),
                ),
              ).animate().fadeIn(delay: (index * 60).ms, duration: 280.ms).slideX(begin: 0.05, end: 0);
            },
          ),
        ),
      ],
    );
  }

  String _capitalize(String s) =>
      s.isEmpty ? s : '${s[0].toUpperCase()}${s.substring(1)}';

  Color _confidenceColor(double confidence) {
    if (confidence >= 0.85) return AppTheme.secondary;
    if (confidence >= 0.65) return AppTheme.accent;
    return Colors.orange;
  }
}
