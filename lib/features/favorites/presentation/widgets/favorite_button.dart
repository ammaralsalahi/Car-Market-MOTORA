import 'package:flutter/material.dart';

import '../../data/favorites_service.dart';

class FavoriteButton extends StatefulWidget {
  final String carId;
  final double size;

  const FavoriteButton({
    super.key,
    required this.carId,
    this.size = 22,
  });

  @override
  State<FavoriteButton> createState() => _FavoriteButtonState();
}

class _FavoriteButtonState extends State<FavoriteButton> {
  static const Color _accent = Color(0xFFF8ED00);

  final FavoritesService _service = FavoritesService();

  bool _isFavorite = false;
  bool _isLoading = true;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _checkFavorite();
  }

  Future<void> _checkFavorite() async {
    try {
      final result = await _service.isFavorite(widget.carId);

      if (!mounted) return;

      setState(() {
        _isFavorite = result;
        _isLoading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _isLoading = false);
    }
  }

  Future<void> _toggleFavorite() async {
    if (_isSaving || _isLoading) return;

    setState(() => _isSaving = true);

    try {
      await _service.toggleFavorite(
        carId: widget.carId,
        isFavorite: _isFavorite,
      );

      if (!mounted) return;

      setState(() {
        _isFavorite = !_isFavorite;
        _isSaving = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            _isFavorite
                ? 'Added to favorites'
                : 'Removed from favorites',
          ),
          duration: const Duration(seconds: 2),
          backgroundColor: const Color(0xFF24262B),
        ),
      );
    } catch (error) {
      if (!mounted) return;

      setState(() => _isSaving = false);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Could not update favorite: $error'),
          backgroundColor: Colors.red.shade800,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.black.withValues(alpha: 0.65),
      shape: const CircleBorder(),
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: _isLoading || _isSaving ? null : _toggleFavorite,
        child: SizedBox(
          width: 43,
          height: 43,
          child: Center(
            child: _isSaving || _isLoading
                ? const SizedBox(
                    width: 17,
                    height: 17,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: _accent,
                    ),
                  )
                : Icon(
                    _isFavorite
                        ? Icons.favorite_rounded
                        : Icons.favorite_border_rounded,
                    color: _isFavorite ? _accent : Colors.white,
                    size: widget.size,
                  ),
          ),
        ),
      ),
    );
  }
}