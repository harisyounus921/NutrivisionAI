import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:image_picker/image_picker.dart';

import '../../../core/navigation/app_page_route.dart';
import '../../../core/services/api_client.dart';
import '../../../core/theme/app_theme.dart';
import '../models/food_item.dart';
import '../services/food_service.dart';
import 'log_portion_screen.dart';

/// Pick or take a photo, upload it to POST /food/recognize,
/// then show results and navigate to LogPortionScreen.
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
  List<FoodItem> _results = [];
  String? _error;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _pickImage(ImageSource.camera));
  }

  Future<void> _pickImage(ImageSource source) async {
    final picked = await _picker.pickImage(source: source, imageQuality: 80);
    if (picked == null) {
      if (mounted) Navigator.of(context).pop();
      return;
    }

    final file = File(picked.path);
    setState(() {
      _image = file;
      _recognizing = true;
      _results = [];
      _error = null;
    });

    try {
      final bytes = await file.readAsBytes();
      final items = await _foodService.recognizePhoto(bytes, filename: picked.name);
      if (!mounted) return;
      if (items.isEmpty) {
        setState(() {
          _recognizing = false;
          _error = 'No food recognized in this photo. Try a clearer image.';
        });
      } else {
        setState(() {
          _recognizing = false;
          _results = items;
        });
      }
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() {
        _recognizing = false;
        _error = e.message;
      });
    } catch (_) {
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
                height: 220,
                width: double.infinity,
                decoration: BoxDecoration(color: Theme.of(context).colorScheme.surfaceContainerHighest),
                child: Image.file(_image!, fit: BoxFit.cover),
              ),
            Expanded(
              child: _recognizing
                  ? _RecognizingPlaceholder()
                  : _error != null
                      ? _ErrorState(
                          message: _error!,
                          onRetry: () => _pickImage(ImageSource.camera),
                        )
                      : _results.isEmpty
                          ? const _EmptyState()
                          : _ResultsList(items: _results, onSelect: _selectItem),
            ),
          ],
        ),
      ),
    );
  }
}

class _RecognizingPlaceholder extends StatelessWidget {
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

class _ResultsList extends StatelessWidget {
  const _ResultsList({required this.items, required this.onSelect});

  final List<FoodItem> items;
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
            '${items.length} food${items.length == 1 ? '' : 's'} recognized — tap to log',
            style: textTheme.titleSmall?.copyWith(color: colorScheme.onSurfaceVariant),
          ),
        ),
        Expanded(
          child: ListView.builder(
            itemCount: items.length,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemBuilder: (context, index) {
              final item = items[index];
              return Card(
                margin: const EdgeInsets.only(bottom: 8),
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: AppTheme.secondary.withValues(alpha: 0.15),
                    child: const Icon(Icons.restaurant_outlined, color: AppTheme.secondary),
                  ),
                  title: Text(item.name, style: textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700)),
                  subtitle: Text('${item.calories.toStringAsFixed(0)} kcal · ${item.servingDescription}'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => onSelect(item),
                ),
              ).animate().fadeIn(delay: (index * 40).ms, duration: 250.ms).slideX(begin: 0.05, end: 0);
            },
          ),
        ),
      ],
    );
  }
}
