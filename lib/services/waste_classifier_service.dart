import 'dart:io';
import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:image/image.dart' as img;
import 'package:tflite_flutter/tflite_flutter.dart';

Object _preprocessImage(Map<String, Object> request) {
  final bytes = request['bytes']! as Uint8List;
  final inputHeight = request['inputHeight']! as int;
  final inputWidth = request['inputWidth']! as int;
  final isFloatModel = request['isFloatModel']! as bool;

  final decodedImage = img.decodeImage(bytes);
  if (decodedImage == null) {
    throw StateError('The selected image could not be decoded.');
  }

  final cropSize = decodedImage.width < decodedImage.height
      ? decodedImage.width
      : decodedImage.height;
  final offsetX = (decodedImage.width - cropSize) ~/ 2;
  final offsetY = (decodedImage.height - cropSize) ~/ 2;
  final croppedImage = img.copyCrop(
    decodedImage,
    x: offsetX,
    y: offsetY,
    width: cropSize,
    height: cropSize,
  );

  final resizedImage = img.copyResize(
    croppedImage,
    width: inputWidth,
    height: inputHeight,
  );

  if (isFloatModel) {
    return [
      List.generate(resizedImage.height, (y) {
        return List.generate(resizedImage.width, (x) {
          final pixel = resizedImage.getPixel(x, y);
          return [pixel.r / 255.0, pixel.g / 255.0, pixel.b / 255.0];
        });
      }),
    ];
  }

  return [
    List.generate(resizedImage.height, (y) {
      return List.generate(resizedImage.width, (x) {
        final pixel = resizedImage.getPixel(x, y);
        return [pixel.r.toInt(), pixel.g.toInt(), pixel.b.toInt()];
      });
    }),
  ];
}

class WasteClassificationResult {
  const WasteClassificationResult({
    required this.label,
    required this.confidence,
    required this.isReliable,
    required this.topPredictions,
  });

  final String label;
  final double confidence;
  final bool isReliable;
  final List<WastePrediction> topPredictions;
}

class WastePrediction {
  const WastePrediction({required this.label, required this.confidence});

  final String label;
  final double confidence;
}

class WasteClassifierService {
  static const String _modelAssetPath = 'assets/model_unquant.tflite';
  static const String _labelsAssetPath = 'assets/labels.txt';
  static const double _minimumReliableConfidence = 60.0;
  static const double _minimumWinningMargin = 12.0;

  Interpreter? _interpreter;
  List<String> _labels = const [];
  List<int> _inputShape = const [1, 224, 224, 3];
  List<int> _outputShape = const [1, 1];
  TensorType _inputType = TensorType.float32;
  TensorType _outputType = TensorType.float32;

  bool get isLoaded => _interpreter != null;

  List<String> get supportedLabels => List.unmodifiable(_labels);

  Future<void> load() async {
    if (_interpreter != null) {
      return;
    }

    final options = InterpreterOptions()..threads = 2;
    _interpreter = await Interpreter.fromAsset(
      _modelAssetPath,
      options: options,
    );
    _labels = await _loadLabels();

    final inputTensor = _interpreter!.getInputTensor(0);
    final outputTensor = _interpreter!.getOutputTensor(0);
    _inputShape = inputTensor.shape;
    _outputShape = outputTensor.shape;
    _inputType = inputTensor.type;
    _outputType = outputTensor.type;
  }

  Future<WasteClassificationResult> classify(File imageFile) async {
    if (_interpreter == null) {
      await load();
    }

    final bytes = await imageFile.readAsBytes();
    final inputHeight = _inputShape.length > 1 ? _inputShape[1] : 224;
    final inputWidth = _inputShape.length > 2 ? _inputShape[2] : 224;
    final input = await compute(_preprocessImage, <String, Object>{
      'bytes': bytes,
      'inputHeight': inputHeight,
      'inputWidth': inputWidth,
      'isFloatModel': _inputType == TensorType.float32,
    });
    final output = _buildOutputTensor();

    _interpreter!.run(input, output);

    final scores = _normalizeScores(_extractScores(output));
    if (scores.isEmpty) {
      throw StateError('The model returned an empty prediction.');
    }

    final rankedPredictions = List.generate(scores.length, (index) {
      final rawLabel = index < _labels.length ? _labels[index] : 'unknown';
      return WastePrediction(
        label: _formatLabel(rawLabel),
        confidence: scores[index] * 100,
      );
    })..sort((first, second) => second.confidence.compareTo(first.confidence));

    final bestPrediction = rankedPredictions.first;
    final secondPrediction = rankedPredictions.length > 1
        ? rankedPredictions[1]
        : const WastePrediction(label: 'Unknown waste', confidence: 0);
    final winningMargin =
        bestPrediction.confidence - secondPrediction.confidence;
    final isReliable =
        bestPrediction.confidence >= _minimumReliableConfidence &&
        winningMargin >= _minimumWinningMargin;

    return WasteClassificationResult(
      label: isReliable ? bestPrediction.label : 'Uncertain result',
      confidence: bestPrediction.confidence,
      isReliable: isReliable,
      topPredictions: rankedPredictions.take(3).toList(growable: false),
    );
  }

  Future<List<String>> _loadLabels() async {
    final rawLabels = await rootBundle.loadString(_labelsAssetPath);
    return _parseLabels(rawLabels.split('\n'));
  }

  List<String> _parseLabels(List<String> lines) {
    return lines
        .map((line) => line.trim())
        .where((line) => line.isNotEmpty)
        .map((line) => line.replaceFirst(RegExp(r'^\d+\s+'), ''))
        .toList(growable: false);
  }

  Object _buildOutputTensor() {
    final outputLength = _outputShape.isEmpty ? 1 : _outputShape.last;
    if (_outputType == TensorType.float32) {
      return [List<double>.filled(outputLength, 0)];
    }

    return [List<int>.filled(outputLength, 0)];
  }

  List<double> _extractScores(Object output) {
    if (output is List) {
      return _flattenNumericList(output);
    }

    throw StateError('Unsupported output format from the TFLite model.');
  }

  List<double> _flattenNumericList(List<dynamic> values) {
    final flattened = <double>[];

    for (final value in values) {
      if (value is num) {
        flattened.add(value.toDouble());
      } else if (value is List) {
        flattened.addAll(_flattenNumericList(value.cast<dynamic>()));
      }
    }

    return flattened;
  }

  List<double> _normalizeScores(List<double> rawScores) {
    if (rawScores.isEmpty) {
      return rawScores;
    }

    final areProbabilities = rawScores.every(
      (score) => score >= 0 && score <= 1,
    );
    final total = rawScores.fold<double>(0, (sum, score) => sum + score);
    if (areProbabilities && total > 0.95 && total < 1.05) {
      return rawScores;
    }

    final maxScore = rawScores.reduce((a, b) => a > b ? a : b);
    final exponentials = rawScores
        .map((score) => math.exp(score - maxScore))
        .toList(growable: false);
    final exponentialTotal = exponentials.fold<double>(
      0,
      (sum, score) => sum + score,
    );
    if (exponentialTotal == 0) {
      return List<double>.filled(rawScores.length, 0);
    }

    return exponentials
        .map((score) => score / exponentialTotal)
        .toList(growable: false);
  }

  String _formatLabel(String rawLabel) {
    final normalized = rawLabel.trim();
    if (normalized.isEmpty) {
      return 'Unknown waste';
    }

    return normalized
        .split(RegExp(r'[\s_-]+'))
        .where((part) => part.isNotEmpty)
        .map((part) => '${part[0].toUpperCase()}${part.substring(1)}')
        .join(' ');
  }

  void close() {
    _interpreter?.close();
    _interpreter = null;
  }
}
