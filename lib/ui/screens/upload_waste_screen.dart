import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../../services/waste_classifier_service.dart';
import '../../models/recycler_company.dart';
import '../../services/recycler_company_service.dart';
import '../../services/company_data_service.dart';
import 'recycler_marketplace_screen.dart';
import 'company_details_screen.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:url_launcher/url_launcher_string.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../services/carbon_impact_service.dart';
import '../../providers/dashboard_providers.dart';
import '../../providers/auth_provider.dart';
import '../../providers/listing_providers.dart';
import 'company_detail_screen.dart';
import 'dashboard_screen.dart';

class UploadWasteScreen extends ConsumerStatefulWidget {
  const UploadWasteScreen({super.key});

  @override
  ConsumerState<UploadWasteScreen> createState() => _UploadWasteScreenState();
}

class _UploadWasteScreenState extends ConsumerState<UploadWasteScreen> {
  // latest weight entered by user (kg) - used to calculate total value
  double _lastLoggedWeight = 0;
  double _enteredWeight = 0; // weight typed by user in price step
  int _currentStep = 0;
  bool _isProcessing = false;
  bool _isModelReady = false;
  File? _image;
  final ImagePicker _picker = ImagePicker();
  final WasteClassifierService _wasteClassifier = WasteClassifierService();
  final TextEditingController _weightController = TextEditingController();

  // AI Detection Results
  String _detectedMaterial = 'Scanning...';
  double _confidence = 0.0;
  String _suggestedPrice = '₹0';
  String _priceRange = '₹0 - ₹0';
  double _pricePerKg = 0; // used for per-kg mapping
  String _scanGuidance = 'Capture a clear image with the waste centered.';
  List<WastePrediction> _topPredictions = const [];

  /// Companies that match the latest detection; computed when the
  /// classifier returns a label. Used when we push the results screen.
  List<RecyclerCompany> _filteredCompanies = [];

  /// all companies loaded from JSON asset; used when filtering results.
  List<RecyclerCompany> _allCompanies = []; // empty until loaded

  // helpers exposed for widget tests
  @visibleForTesting
  List<RecyclerCompany> get testFilteredCompanies => _filteredCompanies;

  @visibleForTesting
  double get testPricePerKg => _pricePerKg;

  @visibleForTesting
  void testSetFilteredCompanies(List<RecyclerCompany> list) {
    setState(() {
      _filteredCompanies = list;
    });
  }

  @visibleForTesting
  void testSetDetectedMaterial(String m) {
    setState(() {
      _detectedMaterial = m;
      _updatePricing(m);
    });
  }

  @visibleForTesting
  void testSetCurrentStep(int s) {
    setState(() {
      _currentStep = s;
    });
  }

  @override
  void initState() {
    super.initState();
    _initializeClassifier();
    _loadCompanies();
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

      ScaffoldMessenger.maybeOf(context)?.showSnackBar(
        const SnackBar(
          content: Text('Could not load the waste detection model.'),
        ),
      );
    }
  }

  @override
  void dispose() {
    _wasteClassifier.close();
    _weightController.dispose();
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
        // compute the companies that accept the detected material
        _filteredCompanies = RecyclerCompanyService.filterByDetectedWaste(
          _detectedMaterial,
          source: _allCompanies.isNotEmpty ? _allCompanies : null,
        );

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
        ScaffoldMessenger.maybeOf(context)?.showSnackBar(
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

  /// load the JSON company list once
  Future<void> _loadCompanies() async {
    try {
      final list = await CompanyDataService.loadFromAsset();
      if (!mounted) return;
      setState(() {
        _allCompanies = list;
      });
    } catch (e) {
      debugPrint('Failed to load company list: $e');
      // leave _allCompanies empty; filter method will fall back to demo list
    }
  }

  void _updatePricing(String material) {
    final normalized = material.toLowerCase();

    // simple mapping provided by specification
    if (normalized.contains('plastic')) {
      _pricePerKg = 20;
    } else if (normalized.contains('paper')) {
      _pricePerKg = 12;
    } else if (normalized.contains('metal')) {
      _pricePerKg = 40;
    } else if (normalized.contains('electronics') ||
        normalized.contains('e waste') ||
        normalized.contains('e-waste')) {
      _pricePerKg = 50;
    } else if (normalized.contains('organic') ||
        normalized.contains('wet waste') ||
        normalized.contains('food')) {
      _pricePerKg = 5;
    } else {
      _pricePerKg = 0;
    }

    // update strings used elsewhere
    if (_pricePerKg > 0) {
      _suggestedPrice = '₹${_pricePerKg.toStringAsFixed(0)}';
      _priceRange = '₹${(_pricePerKg - 2).toStringAsFixed(0)} - ₹${(_pricePerKg + 2).toStringAsFixed(0)}';
    } else {
      _suggestedPrice = '₹0';
      _priceRange = 'Retake scan for pricing';
    }
  }

  @override
  Widget build(BuildContext context) {
    final role = ref.watch(userRoleProvider);
    // Allow null role in tests (no auth context), but enforce buyer vs seller in real usage.
    if (role != null && role != 'seller') {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => const DashboardScreen()),
        );
      });
      return const SizedBox.shrink();
    }

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
    return Column(
      children: [
        Center(
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
        ),
        if (_filteredCompanies.isNotEmpty) ...[
          const SizedBox(height: 30),
          const Align(
            alignment: Alignment.centerLeft,
            child: Text(
              'Matching Companies',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
          ),
          const SizedBox(height: 12),
          ..._filteredCompanies.map(_buildCompanyCard),
        ],
      ],
    );
  }

  Widget _buildPriceStep() {
    final total = (_enteredWeight * _pricePerKg);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
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
              const SizedBox(height: 4),
              if (_pricePerKg > 0)
                Text(
                  'Estimated value for 1 kg: ₹${_pricePerKg.toStringAsFixed(0)}',
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 14,
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(height: 24),
        if (_pricePerKg > 0) ...[
          const Text('Enter weight (kg)', style: TextStyle(fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          TextField(
            controller: _weightController,
            keyboardType: TextInputType.numberWithOptions(decimal: true),
            decoration: const InputDecoration(
              border: OutlineInputBorder(),
              hintText: 'e.g. 1.5',
            ),
            onChanged: (val) {
              final w = double.tryParse(val) ?? 0;
              setState(() {
                _enteredWeight = w;
              });
            },
          ),
          const SizedBox(height: 12),
          if (_enteredWeight > 0)
            Text('Total estimate: ₹${total.toStringAsFixed(0)}', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500)),
        ],
      ],
    );
  }

  Widget _buildBuyersStep() {
    if (_filteredCompanies.isEmpty) {
      return const Center(child: Text('No recycling companies available.'));
    }

    return Column(
      children: [
        const Text(
          'Matching Companies',
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 20),
        ..._filteredCompanies.map(_buildCompanyCard),
      ],
    );
  }

  Widget _buildCompanyCard(RecyclerCompany c) {
    final priceKg = _pricePerKg;
    final priceStr = priceKg > 0 ? '₹${priceKg.toStringAsFixed(0)}/kg' : 'N/A';

    // keep these outside of the builder so they persist across rebuilds
    double localWeight = 0;
    final controller = TextEditingController();

    return StatefulBuilder(
      builder: (context, setLocalState) {
        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          elevation: 2,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(c.name, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                const SizedBox(height: 6),
                Text('${c.category} • ${c.city}'),
                const SizedBox(height: 6),
                Text('Phone: ${c.phone}'),
                Text('Website: ${c.website}'),
                const SizedBox(height: 6),
                Text('Price/kg: $priceStr'),
                const SizedBox(height: 12),
                TextField(
                  controller: controller,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  decoration: const InputDecoration(
                    labelText: 'Weight (kg)',
                    border: OutlineInputBorder(),
                  ),
                  onChanged: (val) {
                    final w = double.tryParse(val) ?? 0;
                    setLocalState(() {
                      localWeight = w;
                    });
                  },
                ),
                const SizedBox(height: 8),
                ElevatedButton(
                  onPressed: () {
                    if (localWeight <= 0 || priceKg <= 0) return;
                    final total = localWeight * priceKg;

                    // create listing and pickup request for seller
                    final seller = ref.read(userNameProvider) ?? '';
                    final sellerLoc = ref.read(userLocationProvider) ?? '';
                    ref.read(listingsProvider.notifier).addListing(
                      WasteListing(
                        wasteType: _detectedMaterial,
                        weightKg: localWeight,
                        pricePerKg: priceKg,
                        totalValue: total,
                        companyName: c.name,
                        sellerName: seller,
                        sellerLocation: sellerLoc,
                      ),
                    );
                    ref.read(pickupRequestsProvider.notifier).addRequest(
                      PickupRequest(
                        sellerName: seller,
                        wasteType: _detectedMaterial,
                        weight: localWeight,
                        companyName: c.name,
                      ),
                    );

                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => CompanyDetailScreen(
                          company: c,
                          weight: localWeight,
                          totalValue: total,
                          pricePerKg: priceKg,
                        ),
                      ),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF00A699),
                    minimumSize: const Size(double.infinity, 44),
                  ),
                  child: const Text('View Details'),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showCompanyActions(RecyclerCompany company) {
    showModalBottomSheet(
      context: context,
      builder: (_) {
        return Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                company.name,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text('Category: ${company.category}'),
              Text('City: ${company.city}'),
              Text('Waste types: ${company.wasteTypes.join(', ')}'),
              Text('Phone: ${company.phone}'),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  ElevatedButton.icon(
                    onPressed: () async {
                      // remove spaces and other characters that might break the tel URI
                      final sanitizedNumber = company.phone.replaceAll(
                        RegExp(r"\s+"),
                        "",
                      );
                      final uri = 'tel:$sanitizedNumber';
                      if (await canLaunchUrlString(uri)) {
                        await launchUrlString(uri);
                      } else {
                        if (mounted) {
                          ScaffoldMessenger.maybeOf(context)?.showSnackBar(
                            const SnackBar(
                              content: Text('Unable to open dialer.'),
                            ),
                          );
                        }
                      }
                    },
                    icon: const Icon(Icons.phone),
                    label: const Text('Call Company'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF00A699),
                    ),
                  ),
                  ElevatedButton.icon(
                    onPressed: () async {
                      // ensure url has a scheme; Firestore data might omit http(s)
                      var url = company.website;
                      if (!url.startsWith('http')) {
                        url = 'https://$url';
                      }
                      if (await canLaunchUrlString(url)) {
                        await launchUrlString(
                          url,
                          mode: LaunchMode.externalApplication,
                        );
                      } else {
                        if (mounted) {
                          ScaffoldMessenger.maybeOf(context)?.showSnackBar(
                            const SnackBar(
                              content: Text('Could not open website.'),
                            ),
                          );
                        }
                      }
                    },
                    icon: const Icon(Icons.language),
                    label: const Text('Visit Website'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF00A699),
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }


  @visibleForTesting
  void testSetEnteredWeight(double w) {
    setState(() {
      _enteredWeight = w;
      _weightController.text = w.toString();
    });
  }

  void _handleNextStep() {
    if (_currentStep == 0) {
      if (_image == null) {
        ScaffoldMessenger.maybeOf(context)?.showSnackBar(
          const SnackBar(content: Text('Please capture an image')),
        );
        return;
      }
      if (!_isModelReady) {
        ScaffoldMessenger.maybeOf(context)?.showSnackBar(
          const SnackBar(
            content: Text('The waste detection model is still loading.'),
          ),
        );
        return;
      }
      _processImage();
    } else if (_currentStep == 2) {
      // record transaction once weight has been entered
      if (_enteredWeight <= 0 || _pricePerKg <= 0) {
        ScaffoldMessenger.maybeOf(context)?.showSnackBar(
          const SnackBar(content: Text('Please enter a valid weight to continue.')),
        );
        return;
      }
      recordRecyclingTransaction(
        wasteType: _detectedMaterial,
        weightKg: _enteredWeight,
      ).catchError((_) {});
      _lastLoggedWeight = _enteredWeight;
      ref.refresh(impactStatsProvider);
      setState(() => _currentStep++);
    } else if (_currentStep < 3) {
      setState(() => _currentStep++);
    } else {
      Navigator.pop(context);
    }
  }}
