import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';

import 'app_colors.dart';
import 'app_state.dart';

/// Avatar circular que muestra la foto de perfil (si existe) o la inicial del
/// nombre. Al pulsarlo permite cambiar la foto o abrir el perfil.
class ProfileAvatar extends StatelessWidget {
  final double size;
  final VoidCallback? onOpenProfile;

  const ProfileAvatar({super.key, this.size = 40, this.onOpenProfile});

  String get _initial {
    final name = AppState.instance.userName.trim();
    if (name.isEmpty) return '?';
    return name.substring(0, 1).toUpperCase();
  }

  Future<void> _pickPhoto(BuildContext context) async {
    final picker = ImagePicker();
    final file = await picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 512,
      maxHeight: 512,
      imageQuality: 85,
    );
    if (file == null) return;
    try {
      // Copia a un directorio persistente de la app.
      final dir = await getApplicationDocumentsDirectory();
      final saved =
          await File(file.path).copy('${dir.path}/profile_photo.jpg');
      await AppState.instance.setProfilePhoto(saved.path);
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('No se pudo guardar: $e')));
      }
    }
  }

  void _showMenu(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.photo_camera_outlined,
                  color: AppColors.emerald),
              title: const Text('Cambiar foto de perfil'),
              onTap: () {
                Navigator.of(ctx).pop();
                _pickPhoto(context);
              },
            ),
            if (onOpenProfile != null)
              ListTile(
                leading: const Icon(Icons.person_outline),
                title: const Text('Ver perfil'),
                onTap: () {
                  Navigator.of(ctx).pop();
                  onOpenProfile!();
                },
              ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<String>(
      valueListenable: AppState.instance.profilePhotoNotifier,
      builder: (context, path, _) {
        return GestureDetector(
          onTap: () => _showMenu(context),
          child: Container(
            width: size,
            height: size,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: AppColors.emerald.withValues(alpha: 0.6),
                width: 2,
              ),
            ),
            clipBehavior: Clip.antiAlias,
            child: path.isNotEmpty && File(path).existsSync()
                ? Image.file(File(path),
                    fit: BoxFit.cover, width: size, height: size)
                : Container(
                    color: AppColors.emerald.withValues(alpha: 0.15),
                    alignment: Alignment.center,
                    child: Text(
                      _initial,
                      style: TextStyle(
                        color: AppColors.emerald,
                        fontSize: size * 0.45,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
          ),
        );
      },
    );
  }
}
