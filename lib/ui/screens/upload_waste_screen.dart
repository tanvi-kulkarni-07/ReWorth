import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:google_mlkit_image_labeling/google_mlkit_image_labeling.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

class UploadWasteScreen extends StatefulWidget {
  const UploadWasteScreen({Key? key}) : super(key: key);

  @override
  State<UploadWasteScreen> createState() => _UploadWasteScreenState();
}

class _UploadWasteScreenState extends State<UploadWasteScreen> {
  int _currentStep = 0;
  bool _isProcessing = false;
  File? _image;
  final ImagePicker _picker = ImagePicker();
  ImageLabeler? _imageLabeler;

  // AI Detection Results
  String _detectedMaterial = 'Scanning...';
  double _confidence = 0.0;
  String _suggestedPrice = '₹0';
  String _priceRange = '₹0 - ₹0';

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
    _initializeLabeler();
  }

  // To use a custom model, we need to ensure the asset is available locally
  Future<String> _getModelPath(String asset) async {
    final localPath = '${(await getApplicationSupportDirectory()).path}/$asset';
    await Directory(p.dirname(localPath)).create(recursive: true);
    final file = File(localPath);
    if (!await file.exists()) {
      final byteData = await rootBundle.load(asset);
      await file.writeAsBytes(byteData.buffer
          .asUint8List(byteData.offsetInBytes, byteData.lengthInBytes));
    }
    return file.path;
  }

  void _initializeLabeler() async {
    try {
      // Step 1: Check if custom model exists in assets
      // Note: You must place your model.tflite in assets/ml/
      final modelPath = await _getModelPath('assets/ml/model.tflite');
      
      final options = LocalLabelerOptions(
        modelPath: modelPath,
        confidenceThreshold: 0.7, // Higher threshold for custom trained models
      );
      _imageLabeler = ImageLabeler(options: options);
      debugPrint('Custom ML Model loaded successfully');
    } catch (e) {
      debugPrint('Custom model not found, falling back to default: $e');
      // Fallback to default if custom model isn't ready yet
      final options = ImageLabelerOptions(confidenceThreshold: 0.5);
      _imageLabeler = ImageLabeler(options: options);
    }
  }

  @override
  void dispose() {
    _imageLabeler?.close();
    super.dispose();
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      final XFile? pickedFile = await _picker.pickImage(
        source: source,
        maxWidth: 1000,
        maxHeight: 1000,
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
    if (_image == null || _imageLabeler == null) return;

    setState(() {
      _isProcessing = true;
    });

    try {
      final inputImage = InputImage.fromFile(_image!);
      final List<ImageLabel> labels = await _imageLabeler!.processImage(inputImage);

      if (labels.isNotEmpty) {
        // Use the new, smarter mapping logic
        final Map<String, dynamic> bestMatch = _mapLabelsToBestWasteCategory(labels);

        setState(() {
          _detectedMaterial = bestMatch['material'];
          _confidence = bestMatch['confidence'];
          _updatePricing(_detectedMaterial);
          _currentStep = 1; 
        });
      } else {
        setState(() {
          _detectedMaterial = 'Unknown Material';
          _confidence = 0.0;
          _currentStep = 1;
        });
      }
    } catch (e) {
      debugPrint('Error processing image: $e');
    } finally {
      setState(() {
        _isProcessing = false;
      });
    }
  }

  void _updatePricing(String material) {
    if (material.contains('Plastic')) {
      _suggestedPrice = '₹25';
      _priceRange = '₹22 - ₹28';
    } else if (material.contains('Paper')) {
      _suggestedPrice = '₹12';
      _priceRange = '₹10 - ₹15';
    } else if (material.contains('Metal')) {
      _suggestedPrice = '₹45';
      _priceRange = '₹40 - ₹55';
    } else {
      _suggestedPrice = '₹15';
      _priceRange = '₹10 - ₹20';
    }
  }

  // --- NEW, SMARTER MAPPING LOGIC ---
  Map<String, dynamic> _mapLabelsToBestWasteCategory(List<ImageLabel> labels) {
    // Define keywords for each of your categories
    final Map<String, List<String>> wasteCategoryKeywords = {
      'Plastic (PET)': ['bottle', 'plastic', 'water bottle', 'polyethylene terephthalate'],
      'Metal / Aluminum': ['can', 'tin', 'aluminum', 'metal', 'beverage can'],
      'Paper / Cardboard': ['paper', 'cardboard', 'box', 'paperboard', 'carton', 'envelope'],
    };

    double bestConfidence = 0.0;
    String bestCategory = 'Unknown Material';

    // Iterate through all labels returned by ML Kit
    for (final label in labels) {
      final currentLabel = label.label.toLowerCase();

      // Check this label against our keyword lists
      for (final category in wasteCategoryKeywords.keys) {
        for (final keyword in wasteCategoryKeywords[category]!) {
          // If a keyword matches, see if it has the highest confidence so far
          if (currentLabel.contains(keyword)) {
            if (label.confidence > bestConfidence) {
              bestConfidence = label.confidence;
              bestCategory = category;
            }
          }
        }
      }
    }

    // If no keyword was matched after checking all labels, fall back to the top result from ML Kit.
    if (bestCategory == 'Unknown Material' && labels.isNotEmpty) {
      bestCategory = labels.first.label; // Use the raw label from Google
      bestConfidence = labels.first.confidence;
    }

    return {'material': bestCategory, 'confidence': bestConfidence * 100};
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
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: _isProcessing
                        ? const CircularProgressIndicator(color: Colors.white)
                        : Text(_currentStep == 0 ? 'Start AI Scan' : 'Continue'),
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
      case 0: return _buildPhotoStep();
      case 1: return _buildDetectStep();
      case 2: return _buildPriceStep();
      case 3: return _buildBuyersStep();
      default: return _buildPhotoStep();
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
        Text('Point your camera at the waste for instant valuation', 
          style: TextStyle(color: Colors.grey[600])),
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
                ? ClipRRect(borderRadius: BorderRadius.circular(18), child: Image.file(_image!, fit: BoxFit.cover))
                : const Icon(Icons.add_a_photo_outlined, size: 80, color: Colors.grey),
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
          const Text('Scan Result', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
          const SizedBox(height: 10),
          Text(_detectedMaterial, style: const TextStyle(fontSize: 32, fontWeight: FontWeight.w900, color: Color(0xFF00A699))),
          Text('Confidence: ${_confidence.toStringAsFixed(1)}%', style: TextStyle(color: Colors.grey[600])),
        ],
      ),
    );
  }

  Widget _buildPriceStep() {
    return Column(
      children: [
        const Text('Estimated Value', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
        const SizedBox(height: 20),
        Container(
          padding: const EdgeInsets.all(30),
          decoration: BoxDecoration(
            color: const Color(0xFF00A699),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Column(
            children: [
              Text(_suggestedPrice, style: const TextStyle(fontSize: 48, fontWeight: FontWeight.bold, color: Colors.white)),
              const Text('per kilogram', style: TextStyle(color: Colors.white70)),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildBuyersStep() {
    return Column(
      children: [
        const Text('Interested Buyers', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
        const SizedBox(height: 20),
        ..._nearbyBuyers.map((b) => ListTile(
          title: Text(b['name']),
          subtitle: Text('${b['distance']} away • ${b['rating']} ⭐'),
          trailing: Text(b['price'], style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF00A699))),
        )),
      ],
    );
  }

  void _handleNextStep() {
    if (_currentStep == 0) {
      if (_image == null) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please capture an image')));
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
