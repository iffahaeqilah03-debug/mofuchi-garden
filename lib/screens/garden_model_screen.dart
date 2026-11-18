import 'package:flutter/material.dart';
import 'package:model_viewer_plus/model_viewer_plus.dart';

class GardenModelViewer extends StatelessWidget {
  const GardenModelViewer({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: SizedBox(
          width: double.infinity,
          height: 500,
          child: ModelViewer(
            backgroundColor: const Color(0xFFF6F8F5),
            // Use your exact file name
            src: 'assets/3D/mofuchi garden v1.glb',
            alt: 'Mofuchi Garden 3D Model',
            ar: false,
            autoRotate: true,
            cameraControls: true,
          ),
        ),
      ),
    );
  }
}