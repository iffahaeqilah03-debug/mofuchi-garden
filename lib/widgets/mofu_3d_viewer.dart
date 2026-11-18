import 'package:flutter/material.dart';
import 'package:model_viewer_plus/model_viewer_plus.dart';

class Mofu3DViewer extends StatelessWidget {
  final String src;
  final bool autoRotate;
  final bool enableZoom;
  final String fallbackEmoji;

  const Mofu3DViewer({
    super.key,
    this.src = 'assets/3d/mofu.glb',
    this.autoRotate = true,
    this.enableZoom = false,
    this.fallbackEmoji = '🪴',
  });

  @override
  Widget build(BuildContext context) {
    return ModelViewer(
      src: src,
      alt: '3D Mofuchi Character',
      autoRotate: autoRotate,
      autoRotateDelay: 1000,
      cameraControls: true,
      disableZoom: !enableZoom,
      backgroundColor: Colors.transparent,
      shadowIntensity: 0.8,
      shadowSoftness: 0.9,
      exposure: 1.1,
    );
  }
}