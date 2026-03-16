import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:image_picker/image_picker.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher_string.dart';

import '../../models/recycler_company.dart';
import '../../providers/auth_provider.dart';
import '../../providers/listing_providers.dart';
import '../../services/recycler_company_service.dart';
import '../../services/waste_classifier_service.dart';
import 'company_detail_screen.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

/// This screen implements a step-by-step seller flow for uploading waste.
///
/// It uses a TensorFlow Lite model to classify the captured photo.
///
/// 1) Capture / select a photo
/// 2) Run the TFLite waste classifier to detect the waste type
/// 3) Show a price estimate per kg with user-entered weight
/// 4) Show matching recycling companies
/// 5) Allow creating a listing + pickup request (stored in memory)
class UploadWasteScreen extends ConsumerStatefulWidget {
  const UploadWasteScreen({super.key});

  @override
  ConsumerState<UploadWasteScreen> createState() => _UploadWasteScreenState();
}

class _UploadWasteScreenState extends ConsumerState<UploadWasteScreen>
    with WidgetsBindingObserver {
  static const _kPrefsKeyImagePath = 'upload_waste_image_path';
  static const _kPrefsKeyStep = 'upload_waste_step';
  static const _kPrefsKeyDetected = 'upload_waste_detected';
  static const _kPrefsKeyConfidence = 'upload_waste_confidence';

  final ImagePicker _picker = ImagePicker();
  final WasteClassifierService _classifier = WasteClassifierService();

  // Camera support (in-app camera preview instead of launching external app)
  CameraController? _cameraController;
  bool _isCameraInitialized = false;
  bool _cameraPermissionGranted = false;
  bool _cameraAvailable = true;

  int _step = 0;
  bool _isProcessing = false;

  Uint8List? _pickedBytes;
  String _detectedMaterial = 'Scanning...';
  double _confidence = 0;
  List<String> _topMatches = [];

  double _pricePerKg = 0;
  double _enteredWeight = 0;
  final TextEditingController _weightController = TextEditingController();

  List<RecyclerCompany> _companies = RecyclerCompanyService.demoCompanies;

  List<RecyclerCompany> get _matchingCompanies {
    final label = _detectedMaterial.toLowerCase();
    if (label.isEmpty) return [];

    return _companies.where((company) {
      return company.wasteTypes
          .map((t) => t.toLowerCase())
          .any((t) => label.contains(t) || t.contains(label));
    }).toList();
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _restoreState();
    _initCamera();
    _loadCompanies();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _cameraController?.dispose();
    _weightController.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);

    // Save state periodically so that if the OS kills the app while the camera is
    // running, the user can return to where they left off.
    if (state == AppLifecycleState.paused) {
      _saveState();
    }
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      final file = await _picker.pickImage(
        source: source,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 70,
      );

      if (file != null) {
        final bytes = await file.readAsBytes();
        if (!mounted) return;

        setState(() {
          _pickedBytes = bytes;
          _step = 0;
          _detectedMaterial = 'Scanning...';
          _confidence = 0;
          _topMatches = [];
          _pricePerKg = 0;
          _enteredWeight = 0;
          _weightController.clear();
        });

        await _saveState();
      }
    } catch (e, st) {
      debugPrint('Image pick failed: $e\n$st');
      _showSnack('Failed to pick image. Please try again.');
    }
  }

  Future<void> _initCamera() async {
    try {
      final status = await Permission.camera.request();
      if (!status.isGranted) {
        _cameraPermissionGranted = false;
        return;
      }
      _cameraPermissionGranted = true;

      final cameras = await availableCameras();
      if (cameras.isEmpty) return;

      final backCamera = cameras.firstWhere(
        (c) => c.lensDirection == CameraLensDirection.back,
        orElse: () => cameras.first,
      );

      _cameraController = CameraController(
        backCamera,
        ResolutionPreset.low,
        enableAudio: false,
        imageFormatGroup: ImageFormatGroup.jpeg,
      );
      await _cameraController!.initialize();

      if (!mounted) return;
      setState(() {
        _isCameraInitialized = true;
      });
    } catch (e, st) {
      debugPrint('Camera init failed: $e\n$st');
      _cameraAvailable = false;
      _showSnack(
        'In-app camera is not available on this device; please use gallery.',
      );
    }
  }

  Future<void> _takePicture() async {
    if (_cameraController == null || !_cameraController!.value.isInitialized) {
      _showSnack('Camera is not ready.');
      return;
    }

    try {
      final file = await _cameraController!.takePicture();
      final bytes = await File(file.path).readAsBytes();
      if (!mounted) return;

      setState(() {
        _pickedBytes = bytes;
        _step = 0;
        _detectedMaterial = 'Scanning...';
        _confidence = 0;
        _topMatches = [];
        _pricePerKg = 0;
        _enteredWeight = 0;
        _weightController.clear();
      });

      await _saveState();
    } catch (e, st) {
      debugPrint('Take picture failed: $e\n$st');
      _showSnack('Failed to take picture. Please try again.');
    }
  }

  Future<void> _runClassifier() async {
    if (_pickedBytes == null) return;

    setState(() => _isProcessing = true);

    final result = await _classifier.classifyBytes(_pickedBytes!);

    setState(() {
      _detectedMaterial = result.label;
      _confidence = result.confidence;
      _topMatches = result.topPredictions
          .map((p) => '${p.label} (${p.confidence.toStringAsFixed(1)}%)')
          .toList();
      _updatePricing(result.label);
      _step = 1;
      _isProcessing = false;
    });

    await _saveState();
  }

  // Helper methods used by unit tests to drive the UI state.
  // These are intentionally kept simple to avoid exposing internal logic.
  void testSetDetectedMaterial(String material) {
    setState(() {
      _detectedMaterial = material;
      _updatePricing(material);
    });
  }

  void testSetFilteredCompanies(List<RecyclerCompany> companies) {
    setState(() {
      _companies = companies;
    });
  }

  void testSetCurrentStep(int step) {
    setState(() {
      _step = step;
    });
  }

  void testSetEnteredWeight(double weight) {
    setState(() {
      _enteredWeight = weight;
      _weightController.text = weight.toString();
    });
  }

  Future<void> testSelectCompany(RecyclerCompany company) async {
    await _selectCompany(company);
  }

  void _updatePricing(String label) {
    final normalized = label.toLowerCase();

    if (normalized.contains('plastic')) {
      _pricePerKg = 20;
    } else if (normalized.contains('paper')) {
      _pricePerKg = 12;
    } else if (normalized.contains('metal')) {
      _pricePerKg = 40;
    } else if (normalized.contains('electronics') ||
        normalized.contains('e-waste') ||
        normalized.contains('e waste')) {
      _pricePerKg = 50;
    } else if (normalized.contains('organic') ||
        normalized.contains('wet waste') ||
        normalized.contains('food')) {
      _pricePerKg = 5;
    } else {
      _pricePerKg = 0;
    }
  }

  void _showSnack(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _saveState() async {
    final prefs = await SharedPreferences.getInstance();
    if (_pickedBytes == null) {
      await prefs.remove(_kPrefsKeyImagePath);
    } else {
      final dir = await getTemporaryDirectory();
      final file = File(p.join(dir.path, 'upload_waste_cached.jpg'));
      await file.writeAsBytes(_pickedBytes!);
      await prefs.setString(_kPrefsKeyImagePath, file.path);
    }

    await prefs.setInt(_kPrefsKeyStep, _step);
    await prefs.setString(_kPrefsKeyDetected, _detectedMaterial);
    await prefs.setDouble(_kPrefsKeyConfidence, _confidence);
  }

  Future<void> _clearSavedState() async {
    final prefs = await SharedPreferences.getInstance();
    final imagePath = prefs.getString(_kPrefsKeyImagePath);

    await prefs.remove(_kPrefsKeyImagePath);
    await prefs.remove(_kPrefsKeyStep);
    await prefs.remove(_kPrefsKeyDetected);
    await prefs.remove(_kPrefsKeyConfidence);

    if (imagePath != null) {
      final file = File(imagePath);
      if (await file.exists()) {
        await file.delete();
      }
    }
  }

  Future<void> _restoreState() async {
    final prefs = await SharedPreferences.getInstance();

    // Restore selected image, if present.
    final imagePath = prefs.getString(_kPrefsKeyImagePath);
    if (imagePath != null) {
      final file = File(imagePath);
      if (await file.exists()) {
        final bytes = await file.readAsBytes();
        if (!mounted) return;
        setState(() {
          _pickedBytes = bytes;
        });
      }
    }

    final storedStep = prefs.getInt(_kPrefsKeyStep);
    if (storedStep != null) {
      _step = storedStep;
    }

    final storedDetected = prefs.getString(_kPrefsKeyDetected);
    if (storedDetected != null) {
      _detectedMaterial = storedDetected;
    }

    final storedConf = prefs.getDouble(_kPrefsKeyConfidence);
    if (storedConf != null) {
      _confidence = storedConf;
    }

    // If we have no cached image anymore, reset the saved progress to avoid
    // accidentally jumping straight to Step 4 (company selection) on reopening.
    if (_pickedBytes == null && _step != 0) {
      _step = 0;
      _detectedMaterial = 'Scanning...';
      _confidence = 0;
      await prefs.remove(_kPrefsKeyStep);
      await prefs.remove(_kPrefsKeyDetected);
      await prefs.remove(_kPrefsKeyConfidence);
    }

    // If we restored state with a photo, also advance to the correct step
    // so the UI doesn't reset unexpectedly on restore.
    if (_pickedBytes != null && _step == 0) {
      setState(() {
        _step = 1;
      });
    }
  }

  Future<void> _loadCompanies() async {
    // Prefer using real company data from Firestore; fall back to bundled JSON for
    // offline/demo scenarios.
    try {
      final snap = await FirebaseFirestore.instance
          .collection('companies')
          .get();
      final companies = snap.docs.map((doc) {
        final data = {...doc.data(), 'id': doc.id};
        return RecyclerCompany.fromJson(data);
      }).toList();

      if (mounted && companies.isNotEmpty) {
        setState(() {
          _companies = companies;
        });
        return;
      }
    } catch (e, st) {
      debugPrint('Failed to load companies from Firestore: $e\n$st');
    }

    // Fallback to bundled sample companies if Firestore is unavailable.
    try {
      final jsonString = await rootBundle.loadString('assets/companies.json');
      final jsonData = json.decode(jsonString) as List<dynamic>;
      final companies = jsonData
          .map((e) => RecyclerCompany.fromJson(e as Map<String, dynamic>))
          .toList();

      if (mounted && companies.isNotEmpty) {
        setState(() {
          _companies = companies;
        });
      }
    } catch (e, st) {
      debugPrint('Failed to load companies from assets: $e\n$st');
      _showSnack('Unable to load companies, using local sample list.');
    }
  }

  Future<void> _nextStep() async {
    if (_step == 0) {
      if (_pickedBytes == null) {
        _showSnack('Please capture or pick a photo first.');
        return;
      }
      await _runClassifier();
      return;
    }

    if (_step == 1) {
      setState(() => _step = 2);
      await _saveState();
      return;
    }

    if (_step == 2) {
      if (_enteredWeight <= 0 || _pricePerKg <= 0) {
        _showSnack('Enter weight and ensure detection succeeded.');
        return;
      }
      setState(() => _step = 3);
      await _saveState();
      return;
    }

    // At step 3 (company selection), offer a quick way to restart the flow.
    if (_step == 3) {
      await _resetFlow();
    }
  }

  void _goBack() {
    if (_step == 0) {
      _resetFlow();
      return;
    }

    setState(() {
      _step = (_step - 1).clamp(0, 3);
    });
    _saveState();
  }

  Future<void> _resetFlow() async {
    setState(() {
      _step = 0;
      _pickedBytes = null;
      _detectedMaterial = 'Scanning...';
      _confidence = 0;
      _topMatches = [];
      _pricePerKg = 0;
      _enteredWeight = 0;
      _weightController.clear();
    });

    await _clearSavedState();
  }

  Widget _buildStepIndicator() {
    final steps = ['Photo', 'Detect', 'Pricing', 'Companies'];

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: List.generate(steps.length, (index) {
          final isActive = index == _step;
          final isComplete = index < _step;

          return Expanded(
            child: Column(
              children: [
                CircleAvatar(
                  radius: 14,
                  backgroundColor: isActive
                      ? const Color(0xFF00A699)
                      : isComplete
                      ? const Color(0xFF00A699).withOpacity(0.55)
                      : Colors.grey.shade300,
                  child: Text(
                    '${index + 1}',
                    style: TextStyle(
                      color: isActive || isComplete
                          ? Colors.white
                          : Colors.black87,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  steps[index],
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 10,
                    color: isActive ? Colors.black87 : Colors.grey[600],
                  ),
                ),
              ],
            ),
          );
        }),
      ),
    );
  }

  Future<void> _selectCompany(RecyclerCompany company) async {
    if (_enteredWeight <= 0 || _pricePerKg <= 0) {
      _showSnack('Enter weight and confirm pricing first.');
      return;
    }

    final total = _enteredWeight * _pricePerKg;
    final sellerId = ref.read(userIdProvider) ?? 'unknown';
    final sellerName = ref.read(userNameProvider) ?? 'Seller';

    ref
        .read(listingsProvider.notifier)
        .addListing(
          WasteListing(
            wasteType: _detectedMaterial,
            weightKg: _enteredWeight,
            pricePerKg: _pricePerKg,
            totalValue: total,
            companyName: company.name,
            sellerName: sellerName,
            sellerLocation: 'Unknown',
          ),
        );

    await FirebaseFirestore.instance.collection('pickup_requests').add({
      'sellerId': sellerId,
      'sellerName': sellerName,
      'wasteType': _detectedMaterial,
      'weight': _enteredWeight,
      'companyName': company.name,
      'status': 'pending',
      'createdAt': FieldValue.serverTimestamp(),
    });

    _showSnack('Listing created and pickup request recorded.');

    await _clearSavedState();

    if (!mounted) return;

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => CompanyDetailScreen(
          company: company,
          weight: _enteredWeight,
          totalValue: total,
          pricePerKg: _pricePerKg,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final listings = ref.watch(listingsProvider);
    final pickupRequests = ref.watch(pickupRequestsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Upload Waste'),
        backgroundColor: const Color(0xFF00A699),
      ),
      body: Column(
        children: [
          _buildStepIndicator(),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: _buildStep(),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                Text(
                  'Listings: ${listings.length}  |  Pickups: ${pickupRequests.length}',
                  style: TextStyle(color: Colors.grey[700]),
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: _isProcessing ? null : _goBack,
                    child: Text(_step == 0 ? 'Start Over' : 'Back'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: _isProcessing ? null : _nextStep,
                    style: ElevatedButton.styleFrom(
                      minimumSize: const Size(double.infinity, 52),
                    ),
                    child: _isProcessing
                        ? const CircularProgressIndicator(color: Colors.white)
                        : Text(
                            _step == 0
                                ? 'Scan Waste'
                                : _step == 1
                                ? 'Continue to Pricing'
                                : _step == 2
                                ? 'Continue to Companies'
                                : 'Start Over',
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

  Widget _buildStep() {
    switch (_step) {
      case 0:
        return _buildPhotoStep();
      case 1:
        return _buildDetectionStep();
      case 2:
        return _buildPricingStep();
      case 3:
        return _buildCompanySelectionStep();
      default:
        return _buildPhotoStep();
    }
  }

  Widget _buildPhotoStep() {
    return Column(
      children: [
        const Text(
          'Step 1: Capture a photo',
          style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 16),
        Expanded(
          child: Center(
            child: LayoutBuilder(
              builder: (context, constraints) {
                final size = constraints.maxWidth * 0.9;
                return Container(
                  width: size,
                  height: size,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(color: Colors.grey.shade300, width: 2),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(18),
                    child: _pickedBytes != null
                        ? Image.memory(_pickedBytes!, fit: BoxFit.cover)
                        : !_cameraAvailable
                        ? const Center(
                            child: Text(
                              'In-app camera is not supported on this device. Please use gallery.',
                              textAlign: TextAlign.center,
                            ),
                          )
                        : !_cameraPermissionGranted
                        ? Center(
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Text(
                                  'Camera permission is required to capture photos.',
                                  textAlign: TextAlign.center,
                                ),
                                const SizedBox(height: 12),
                                ElevatedButton(
                                  onPressed: _initCamera,
                                  child: const Text('Allow Camera Access'),
                                ),
                              ],
                            ),
                          )
                        : _isCameraInitialized
                        ? Stack(
                            fit: StackFit.expand,
                            alignment: Alignment.bottomCenter,
                            children: [
                              CameraPreview(_cameraController!),
                              Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    begin: Alignment.topCenter,
                                    end: Alignment.bottomCenter,
                                    colors: [
                                      Colors.black.withOpacity(0.0),
                                      Colors.black.withOpacity(0.35),
                                    ],
                                  ),
                                ),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    ElevatedButton.icon(
                                      onPressed: _takePicture,
                                      icon: const Icon(Icons.camera),
                                      label: const Text('Capture'),
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: Colors.white70,
                                        foregroundColor: Colors.black,
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    ElevatedButton.icon(
                                      onPressed: () =>
                                          _pickImage(ImageSource.gallery),
                                      icon: const Icon(Icons.photo),
                                      label: const Text('Gallery'),
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: Colors.white70,
                                        foregroundColor: Colors.black,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          )
                        : const Center(
                            child: Text(
                              'Initializing camera…',
                              textAlign: TextAlign.center,
                            ),
                          ),
                  ),
                );
              },
            ),
          ),
        ),
        const SizedBox(height: 12),
        const Text(
          'Use the in-app camera to capture a photo or choose one from your gallery.',
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildDetectionStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Text(
          'Step 2: Detected material',
          style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 16),
        Card(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          elevation: 2,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Result',
                  style: TextStyle(fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 8),
                Text(
                  _detectedMaterial,
                  style: const TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Confidence: ${_confidence.toStringAsFixed(1)}%',
                  style: const TextStyle(color: Colors.black54),
                ),
                const SizedBox(height: 12),
                const Text(
                  'Top predictions',
                  style: TextStyle(fontWeight: FontWeight.w600),
                ),
                ..._topMatches.map(
                  (m) => Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: Text('• $m'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPricingStep() {
    final total = (_enteredWeight * _pricePerKg);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Text(
          'Step 3: Pricing',
          style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 16),
        Text(
          'Detected: $_detectedMaterial',
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _weightController,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          decoration: const InputDecoration(
            labelText: 'Weight (kg)',
            border: OutlineInputBorder(),
          ),
          onChanged: (value) {
            final w = double.tryParse(value) ?? 0;
            setState(() => _enteredWeight = w);
          },
        ),
        const SizedBox(height: 10),
        Text(
          'Estimated value for 1\u202Fkg: ₹${_pricePerKg.toStringAsFixed(0)}',
          style: const TextStyle(fontSize: 16, color: Colors.black87),
        ),
        const SizedBox(height: 20),
        Card(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          elevation: 2,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Price/kg: ₹${_pricePerKg.toStringAsFixed(0)}',
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 8),
                Text(
                  'Total estimate: ₹${total.toStringAsFixed(0)}',
                  style: const TextStyle(fontSize: 18),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildCompanySelectionStep() {
    final companies = _matchingCompanies;

    if (companies.isEmpty) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text(
            'Step 4: Choose a company',
            style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          const Text(
            'No matching companies found. Please retake your photo or try a different item.',
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: _resetFlow,
            child: const Text('Start over'),
          ),
        ],
      );
    }

    final totalEstimate = (_enteredWeight * _pricePerKg);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Text(
          'Step 4: Choose a company',
          style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _weightController,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          decoration: const InputDecoration(
            labelText: 'Weight (kg)',
            border: OutlineInputBorder(),
          ),
          onChanged: (value) {
            final w = double.tryParse(value) ?? 0;
            setState(() => _enteredWeight = w);
          },
        ),
        const SizedBox(height: 8),
        Text(
          'Estimated value: ₹${totalEstimate.toStringAsFixed(0)}',
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 12),
        Expanded(
          child: ListView.builder(
            itemCount: companies.length,
            itemBuilder: (context, index) {
              final company = companies[index];
              return Card(
                margin: const EdgeInsets.symmetric(vertical: 8),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
                elevation: 2,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        company.name,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text('City: ${company.city}'),
                      Text('Accepts: ${company.wasteTypes.join(', ')}'),
                      Text('Phone: ${company.phone}'),
                      Text('Website: ${company.website}'),
                      Text('Price/kg: ₹${_pricePerKg.toStringAsFixed(0)}/kg'),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Expanded(
                            child: ElevatedButton(
                              onPressed: () => _selectCompany(company),
                              child: const Text('View Details'),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: ElevatedButton(
                              onPressed: () async {
                                final url = company.website.startsWith('http')
                                    ? company.website
                                    : 'https://${company.website}';
                                if (await canLaunchUrlString(url)) {
                                  await launchUrlString(
                                    url,
                                    mode: LaunchMode.externalApplication,
                                  );
                                } else {
                                  _showSnack('Unable to open website.');
                                }
                              },
                              child: const Text('Website'),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      ElevatedButton.icon(
                        onPressed: () async {
                          final sanitized = company.phone.replaceAll(
                            RegExp(r"\s+"),
                            '',
                          );
                          final uri = 'tel:$sanitized';
                          if (await canLaunchUrlString(uri)) {
                            await launchUrlString(uri);
                          } else {
                            _showSnack('Unable to open dialer.');
                          }
                        },
                        icon: const Icon(Icons.phone),
                        label: const Text('Call'),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}
