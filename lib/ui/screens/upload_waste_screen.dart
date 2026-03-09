import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../../services/waste_classifier_service.dart';

class UploadWasteScreen extends StatefulWidget {
  const UploadWasteScreen({super.key});

  @override
  State<UploadWasteScreen> createState() => _UploadWasteScreenState();
}

class _UploadWasteScreenState extends State<UploadWasteScreen> {
  int _currentStep = 0;
  bool _isProcessing = false;
  bool _isModelReady = false;
  File? _image;
  final ImagePicker _picker = ImagePicker();
  final WasteClassifierService _wasteClassifier = WasteClassifierService();

  // AI Detection Results
  String _detectedMaterial = 'Scanning...';
  double _confidence = 0.0;
  String _suggestedPrice = '₹0';
  String _priceRange = '₹0 - ₹0';
  String _scanGuidance = 'Capture a clear image with the waste centered.';
  List<WastePrediction> _topPredictions = const [];

  final List<Map<String, dynamic>> _nearbyBuyers = [
    {
      'name': 'EcoRecycle Hub',
      'distance': '2.3 km',
      'rating': '4.8',
      'price': '₹26/kg',
      'verified': true,
    },
    {
      'name': 'Green Collectors',
      'distance': '3.1 km',
      'rating': '4.6',
      'price': '₹25/kg',
      'verified': true,
    },
  ];

  @override
  void initState() {
    super.initState();
    _initializeClassifier();
  }

  Future<void> _initializeClassifier() async {
    try {
      await _wasteClassifier.load();
      if (!mounted) {
        return;
      }

      setState(() {
        _isModelReady = true;
      });
    } catch (e) {
      debugPrint('Failed to load waste classifier model: $e');
      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Could not load the waste detection model.'),
        ),
      );
    }
  }

  @override
  void dispose() {
    _wasteClassifier.close();
    super.dispose();
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      final XFile? pickedFile = await _picker.pickImage(
        source: source,
        maxWidth: 1280,
        maxHeight: 1280,
        imageQuality: 80,
      );

      if (pickedFile != null) {
        setState(() {
          _image = File(pickedFile.path);
        });
      }
    } catch (e) {
      debugPrint('Error picking image: $e');
    }
  }

  Future<void> _processImage() async {
    if (_image == null || !_isModelReady) {
      return;
    }

    setState(() {
      _isProcessing = true;
    });

    try {
      await Future<void>.delayed(Duration.zero);
      final result = await _wasteClassifier.classify(_image!);

      setState(() {
        _detectedMaterial = result.label;
        _confidence = result.confidence;
        _topPredictions = result.topPredictions;
        _scanGuidance = result.isReliable
            ? 'Model confidence is good enough to estimate pricing.'
            : 'Low-confidence result. Retake the photo with a single waste item filling most of the frame.';
        _updatePricing(result.isReliable ? _detectedMaterial : '');
        _currentStep = 1;
      });
    } catch (e) {
      debugPrint('Error processing image: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Waste detection failed for the selected image.'),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isProcessing = false;
        });
      }
    }
  }

  void _updatePricing(String material) {
    final normalized = material.toLowerCase();

    if (normalized.contains('plastic')) {
      _suggestedPrice = '₹25';
      _priceRange = '₹22 - ₹28';
    } else if (normalized.contains('paper')) {
      _suggestedPrice = '₹12';
      _priceRange = '₹10 - ₹15';
    } else if (normalized.contains('metal')) {
      _suggestedPrice = '₹45';
      _priceRange = '₹40 - ₹55';
    } else if (normalized.contains('e waste') ||
        normalized.contains('e-waste')) {
      _suggestedPrice = '₹60';
      _priceRange = '₹45 - ₹75';
    } else if (normalized.contains('glass')) {
      _suggestedPrice = '₹8';
      _priceRange = '₹5 - ₹10';
    } else if (normalized.contains('textile')) {
      _suggestedPrice = '₹18';
      _priceRange = '₹12 - ₹25';
    } else if (normalized.contains('rubber')) {
      _suggestedPrice = '₹20';
      _priceRange = '₹15 - ₹24';
    } else if (normalized.contains('wet waste')) {
      _suggestedPrice = '₹6';
      _priceRange = '₹4 - ₹8';
    } else {
      _suggestedPrice = '₹0';
      _priceRange = 'Retake scan for pricing';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        backgroundColor: const Color(0xFF00A699),
        foregroundColor: Colors.white,
        title: const Text('AI Waste Recognition'),
        elevation: 0,
      ),
      body: Column(
        children: [
          // Progress Bar
          LinearProgressIndicator(
            value: (_currentStep + 1) / 4,
            backgroundColor: Colors.grey[200],
            color: const Color(0xFF00A699),
          ),

          // Content
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: _buildStepContent(),
            ),
          ),

          // Bottom Actions
          Container(
            padding: const EdgeInsets.all(20),
            decoration: const BoxDecoration(
              color: Colors.white,
              boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 10)],
            ),
            child: Row(
              children: [
                if (_currentStep > 0)
                  IconButton(
                    onPressed: () => setState(() => _currentStep--),
                    icon: const Icon(Icons.arrow_back),
                  ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: _isProcessing ? null : _handleNextStep,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF00A699),
                      minimumSize: const Size(double.infinity, 54),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: _isProcessing
                        ? const CircularProgressIndicator(color: Colors.white)
                        : Text(
                            _currentStep == 0 ? 'Start AI Scan' : 'Continue',
                          ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStepContent() {
    switch (_currentStep) {
      case 0:
        return _buildPhotoStep();
      case 1:
        return _buildDetectStep();
      case 2:
        return _buildPriceStep();
      case 3:
        return _buildBuyersStep();
      default:
        return _buildPhotoStep();
    }
  }

  Widget _buildPhotoStep() {
    return Column(
      children: [
        const Text(
          'Identify Material',
          style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        Text(
          'Point your camera at the waste for instant valuation',
          style: TextStyle(color: Colors.grey[600]),
        ),
        const SizedBox(height: 12),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: _isModelReady
                ? const Color(0xFFE7F8F6)
                : const Color(0xFFFFF3E0),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            _isModelReady
                ? 'Custom waste model is ready. Supported classes: ${_wasteClassifier.supportedLabels.join(', ')}'
                : 'Loading custom waste detection model...',
            style: TextStyle(
              color: _isModelReady
                  ? const Color(0xFF00695C)
                  : const Color(0xFF8A5A00),
            ),
          ),
        ),
        const SizedBox(height: 30),
        GestureDetector(
          onTap: () => _pickImage(ImageSource.camera),
          child: Container(
            height: 300,
            width: double.infinity,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colors.grey[300]!, width: 2),
            ),
            child: _image != null
                ? ClipRRect(
                    borderRadius: BorderRadius.circular(18),
                    child: Image.file(_image!, fit: BoxFit.cover),
                  )
                : const Icon(
                    Icons.add_a_photo_outlined,
                    size: 80,
                    color: Colors.grey,
                  ),
          ),
        ),
        const SizedBox(height: 20),
        Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () => _pickImage(ImageSource.camera),
                icon: const Icon(Icons.camera),
                label: const Text('Camera'),
              ),
            ),
            const SizedBox(width: 15),
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () => _pickImage(ImageSource.gallery),
                icon: const Icon(Icons.photo),
                label: const Text('Gallery'),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildDetectStep() {
    return Center(
      child: Column(
        children: [
          const Icon(Icons.auto_awesome, size: 80, color: Color(0xFF00A699)),
          const SizedBox(height: 20),
          const Text(
            'Scan Result',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 10),
          Text(
            _detectedMaterial,
            style: const TextStyle(
              fontSize: 32,
              fontWeight: FontWeight.w900,
              color: Color(0xFF00A699),
            ),
          ),
          Text(
            'Confidence: ${_confidence.toStringAsFixed(1)}%',
            style: TextStyle(color: Colors.grey[600]),
          ),
          const SizedBox(height: 12),
          Text(
            _scanGuidance,
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.grey[700]),
          ),
          if (_topPredictions.isNotEmpty) ...[
            const SizedBox(height: 20),
            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'Top matches',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: Colors.grey[800],
                ),
              ),
            ),
            const SizedBox(height: 10),
            ..._topPredictions.map(
              (prediction) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(prediction.label),
                    Text('${prediction.confidence.toStringAsFixed(1)}%'),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildPriceStep() {
    return Column(
      children: [
        const Text(
          'Estimated Value',
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 20),
        Container(
          padding: const EdgeInsets.all(30),
          decoration: BoxDecoration(
            color: const Color(0xFF00A699),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Column(
            children: [
              Text(
                _suggestedPrice,
                style: const TextStyle(
                  fontSize: 48,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const Text(
                'per kilogram',
                style: TextStyle(color: Colors.white70),
              ),
              const SizedBox(height: 8),
              Text(
                _priceRange,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildBuyersStep() {
    return Column(
      children: [
        const Text(
          'Interested Buyers',
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 20),
        ..._nearbyBuyers.map(
          (b) => ListTile(
            title: Text(b['name']),
            subtitle: Text('${b['distance']} away • ${b['rating']} ⭐'),
            trailing: Text(
              b['price'],
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                color: Color(0xFF00A699),
              ),
            ),
          ),
        ),
      ],
    );
  }

  void _handleNextStep() {
    if (_currentStep == 0) {
      if (_image == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please capture an image')),
        );
        return;
      }
      if (!_isModelReady) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('The waste detection model is still loading.'),
          ),
        );
        return;
      }
      _processImage();
    } else if (_currentStep < 3) {
      setState(() => _currentStep++);
    } else {
      Navigator.pop(context);
    }
  }
}
