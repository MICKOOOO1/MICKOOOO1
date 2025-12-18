import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:tflite_flutter/tflite_flutter.dart' as tfl;
import 'package:image/image.dart' as img;
import 'package:flutter/services.dart';
import 'scan_history.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen>
    with SingleTickerProviderStateMixin {
  File? _image;
  late tfl.Interpreter _interpreter;
  late List<String> _labels;
  List<double> _probabilities = [];
  bool _isClassifying = false;

  static const Color _purple = Color(0xFF9B5CFF);

  late AnimationController _fadeController;

  final Map<String, String> _descriptions = {
    'Adzuki Bean':
        'Adzuki beans (Vigna angularis) are small, reddish-brown legumes popular in East Asian cuisine, known for their slightly sweet, nutty flavor and versatility, often cooked and sweetened into a paste (anko) for desserts like mochi and dorayaki, or used in savory dishes with rice. Rich in fiber, protein, and minerals, they\'re a nutritious addition to diets and are processed into flours, toppings, and even coffee substitutes.',
    'Black Beans':
        'The black turtle bean is a small, shiny variety of the common bean especially popular in Latin American cuisine, though it can also be found in the Cajun and Creole cuisines of south Louisiana. Like all varieties of the common bean, it is native to the Americas, but has been introduced around the world.',
    'Garbanzo Beans':
        'Garbanzo beans, also known as chickpeas, are a nutritious and versatile legume from the pea family, valued for their high protein, fiber, and micronutrient content. They are a staple food in many cuisines, enjoyed in dishes from hummus to stews, and are available dried or canned.',
    'Green Bean':
        'Green beans are the young, unripe fruits of the common bean plant (Phaseolus vulgaris), widely consumed as a vegetable. They are known by many other names, including snap beans, string beans (though most modern varieties are stringless), and French beans.',
    'Kidney Beans':
        'Kidney beans are nutritious, kidney-shaped legumes (a type of common bean) known for their high protein, fiber, minerals, and antioxidants, making them great for heart health, blood sugar, and digestion, but must be cooked thoroughly as raw beans are toxic. Available in red, white, or black, they\'re a staple in dishes like chili con carne, stews, and salads, providing essential nutrients for vegetarians and a plant-based protein boost.',
    'Lima Bean':
        'Lima beans, also known as butter beans, are nutritious legumes (Phaseolus lunatus) prized for their mild flavor and creamy texture, available fresh, dried, canned, or frozen; they\'re a great source of protein, fiber, iron, and folate, offering benefits for heart and digestive health, and come in varieties like small green sieva or large white butter types, often used in succotash or simply seasoned.',
    'Mung Bean':
        'Mung beans (Vigna radiata) are small, green legumes, vital in Asian cuisine for both sweet and savory dishes, used whole, split (moong dal), or sprouted (bean sprouts). Native to India, they\'re a highly nutritious, versatile food, rich in protein, fiber, vitamins, and minerals, supporting heart, diabetes, and overall health due to compounds like polyphenols.',
    'Navy Bean':
        'Navy beans, also known as haricot beans, pea beans, or Boston beans, are small, oval-shaped white legumes with a mild flavor and a soft, creamy texture when cooked. They were named "navy beans" because they were a staple food in the U.S. Navy diet during the 19th and 20th centuries due to their long shelf life, low cost, and high nutritional value.',
    'Pinto Beans':
        'Pinto beans are a popular, nutritious, oval-shaped legume (Phaseolus vulgaris) known for their earthy flavor, beige skin with reddish-brown speckles that fade to solid light brown when cooked, and use in dishes like Mexican refried beans, stews, and soups. They\'re packed with protein, fiber, iron, folate, and antioxidants, offering heart and blood sugar benefits, and are versatile for meals, often served whole, mashed, or with rice and cornbread.',
    'Soy Beans':
        'Soybeans (Glycine max) are a versatile legume from East Asia, prized globally for their high protein and oil, serving as a staple in vegetarian diets and for animal feed, processed into products like tofu, soy milk, oil, and sauce, and valued for their health benefits (heart, bone) and industrial uses, with major production in the US and Brazil.',
  };

  @override
  void initState() {
    super.initState();
    _loadModel();
    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
  }

  @override
  void dispose() {
    _interpreter.close();
    _fadeController.dispose();
    super.dispose();
  }

  Future<void> _loadModel() async {
    _interpreter = await tfl.Interpreter.fromAsset(
      'assets/tflite/model_unquant.tflite',
    );
    _labels = await rootBundle
        .loadString('assets/tflite/labels.txt')
        .then((v) => v.split('\n').where((e) => e.isNotEmpty).toList());
  }

  Future<void> _pickImage(ImageSource source) async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: source);

    if (pickedFile == null) return;

    setState(() {
      _image = File(pickedFile.path);
      _probabilities.clear();
      _isClassifying = true;
    });

    await _classifyImage();
    _fadeController.forward(from: 0);
  }

  Future<void> _classifyImage() async {
    final image = img.decodeImage(_image!.readAsBytesSync())!;
    final resized = img.copyResize(image, width: 224, height: 224);

    final input = List.generate(
      1,
      (_) => List.generate(
        224,
        (y) => List.generate(224, (x) {
          final p = resized.getPixel(x, y);
          return [p.r / 255, p.g / 255, p.b / 255];
        }),
      ),
    );

    final output = [List.filled(_labels.length, 0.0)];
    _interpreter.run(input, output);

    final probs = List<double>.from(output[0]);

    // Find the top prediction
    double maxProb = 0;
    int maxIndex = 0;
    for (int i = 0; i < probs.length; i++) {
      if (probs[i] > maxProb) {
        maxProb = probs[i];
        maxIndex = i;
      }
    }

    // Save scan result
    final scanResult = ScanResult(
      beanType: _labels[maxIndex],
      confidence: maxProb,
      timestamp: DateTime.now(),
      imagePath: _image!.path,
    );
    await ScanHistory.saveScan(scanResult);

    setState(() {
      _probabilities = probs;
      _isClassifying = false;
    });
  }



  @override
  Widget build(BuildContext context) {
    final purple = _purple;
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    final overlay = SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
      statusBarBrightness: Brightness.dark,
    );
    SystemChrome.setSystemUIOverlayStyle(overlay);

    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      body: AnnotatedRegion<SystemUiOverlayStyle>(
        value: overlay,
        child: SafeArea(
          top: false,
          child: Column(
            children: [
              // Purple header
              Container(
                width: double.infinity,
                padding: EdgeInsets.fromLTRB(
                  18,
                  MediaQuery.of(context).padding.top + 20,
                  18,
                  20,
                ),
                decoration: BoxDecoration(
                  color: purple.withOpacity(0.95),
                  borderRadius: const BorderRadius.only(
                    bottomLeft: Radius.circular(28),
                    bottomRight: Radius.circular(28),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Beans Scanner',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Scan or upload images for analysis',
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.9),
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),

              // Content
              Expanded(
                child: SingleChildScrollView(
                  padding: EdgeInsets.symmetric(
                    horizontal: MediaQuery.of(context).size.width > 600 ? 32 : 18,
                    vertical: MediaQuery.of(context).size.height > 800 ? 24 : 20,
                  ),
                  child: Column(
                    children: [
                      // Image card
                      Container(
                        width: double.infinity,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(18),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.06),
                              blurRadius: 18,
                              offset: const Offset(0, 8),
                            ),
                          ],
                        ),
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          children: [
                            Container(
                              height: MediaQuery.of(context).size.height > 600 ? 250 : 220,
                              constraints: BoxConstraints(
                                maxHeight: MediaQuery.of(context).size.height * 0.35,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.grey.shade100,
                                borderRadius: BorderRadius.circular(14),
                              ),
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(14),
                                child: _image != null
                                    ? Image.file(_image!, fit: BoxFit.cover)
                                    : Container(
                                        color: Colors.white,
                                        child: Column(
                                          mainAxisAlignment:
                                              MainAxisAlignment.center,
                                          children: [
                                            Icon(
                                              Icons.image_outlined,
                                              color: purple,
                                              size: MediaQuery.of(context).size.width > 600 ? 64 : 58,
                                            ),
                                            const SizedBox(height: 10),
                                            Text(
                                              'No image selected',
                                              style: TextStyle(
                                                color: Colors.grey.shade700,
                                                fontSize: MediaQuery.of(context).size.width > 600 ? 18 : 16,
                                                fontWeight: FontWeight.w600,
                                              ),
                                            ),
                                            const SizedBox(height: 6),
                                            Text(
                                              'Choose camera or gallery below',
                                              style: TextStyle(
                                                color: Colors.grey.shade500,
                                                fontSize: MediaQuery.of(context).size.width > 600 ? 15 : 14,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 18),

                      // Buttons row
                      if (MediaQuery.of(context).size.width > 500)
                        Row(
                          children: [
                            Expanded(
                              child: ElevatedButton.icon(
                                onPressed: () => _pickImage(ImageSource.camera),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: purple,
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 16,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(14),
                                  ),
                                ),
                                icon: const Icon(
                                  Icons.camera_alt,
                                  color: Colors.white,
                                ),
                                label: const Text(
                                  'Camera',
                                  style: TextStyle(color: Colors.white),
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: OutlinedButton.icon(
                                onPressed: () => _pickImage(ImageSource.gallery),
                                style: OutlinedButton.styleFrom(
                                  side: BorderSide(color: purple, width: 2),
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 16,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(14),
                                  ),
                                ),
                                icon: Icon(Icons.photo, color: purple),
                                label: Text(
                                  'Gallery',
                                  style: TextStyle(color: purple),
                                ),
                              ),
                            ),
                          ],
                        )
                      else
                        Column(
                          children: [
                            SizedBox(
                              width: double.infinity,
                              child: ElevatedButton.icon(
                                onPressed: () => _pickImage(ImageSource.camera),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: purple,
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 16,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(14),
                                  ),
                                ),
                                icon: const Icon(
                                  Icons.camera_alt,
                                  color: Colors.white,
                                ),
                                label: const Text(
                                  'Camera',
                                  style: TextStyle(color: Colors.white),
                                ),
                              ),
                            ),
                            const SizedBox(height: 12),
                            SizedBox(
                              width: double.infinity,
                              child: OutlinedButton.icon(
                                onPressed: () => _pickImage(ImageSource.gallery),
                                style: OutlinedButton.styleFrom(
                                  side: BorderSide(color: purple, width: 2),
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 16,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(14),
                                  ),
                                ),
                                icon: Icon(Icons.photo, color: purple),
                                label: Text(
                                  'Gallery',
                                  style: TextStyle(color: purple),
                                ),
                              ),
                            ),
                          ],
                        ),

                      const SizedBox(height: 18),

                      // How to use box
                      Container(
                        width: double.infinity,
                        decoration: BoxDecoration(
                          color: Colors.blue.shade50,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.blue.shade100),
                        ),
                        padding: const EdgeInsets.all(14),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'How to use:',
                              style: TextStyle(
                                color: Colors.blue.shade800,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: const [
                                Text('• Tap Camera to take a new photo'),
                                SizedBox(height: 6),
                                Text(
                                  '• Tap Gallery to choose from your photos',
                                ),
                                SizedBox(height: 6),
                                Text(
                                  '• Ensure the subject is well-lit and in focus',
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),

                      // classification progress indicator only
                      if (_isClassifying)
                        const Padding(
                          padding: EdgeInsets.all(16),
                          child: CircularProgressIndicator(),
                        )
                      else if (_probabilities.isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Top Prediction
                              Text(
                                'Top Prediction',
                                style: TextStyle(
                                  fontSize: MediaQuery.of(context).size.width > 600 ? 20 : 18,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.black87,
                                ),
                              ),
                              const SizedBox(height: 12),
                              Builder(
                                builder: (context) {
                                  // pair labels with probabilities and sort descending
                                  final pairs = List.generate(
                                    _labels.length,
                                    (i) =>
                                        MapEntry(_labels[i], _probabilities[i]),
                                  );
                                  pairs.sort(
                                    (a, b) => b.value.compareTo(a.value),
                                  );

                                  final topLabel = pairs[0].key;
                                  final topProb = pairs[0].value;
                                  final topDescription =
                                      _descriptions[topLabel] ??
                                      'No description available.';

                                  // cycling palette for the left label color / bar fill
                                  final palette = [
                                    Colors.deepPurple,
                                    Colors.blue,
                                    Colors.orange,
                                    Colors.pink,
                                    Colors.purple,
                                    Colors.teal,
                                  ];
                                  final topColor = palette[0 % palette.length];

                                  return Padding(
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 8,
                                    ),
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          children: [
                                            // colored label text
                                            Expanded(
                                              child: Text(
                                                topLabel,
                                                style: TextStyle(
                                                  color: topColor,
                                                  fontWeight: FontWeight.w600,
                                                ),
                                              ),
                                            ),

                                            // percentage pill
                                            Container(
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                    horizontal: 8,
                                                    vertical: 6,
                                                  ),
                                              decoration: BoxDecoration(
                                                color: topColor.withOpacity(
                                                  0.95,
                                                ),
                                                borderRadius:
                                                    BorderRadius.circular(8),
                                              ),
                                              child: Text(
                                                '${(topProb * 100).toStringAsFixed(0)}%',
                                                style: const TextStyle(
                                                  color: Colors.white,
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 8),
                                        ClipRRect(
                                          borderRadius: BorderRadius.circular(
                                            8,
                                          ),
                                          child: LinearProgressIndicator(
                                            value: topProb,
                                            minHeight: 18,
                                            valueColor:
                                                AlwaysStoppedAnimation<Color>(
                                                  topColor,
                                                ),
                                            backgroundColor: topColor
                                                .withOpacity(0.12),
                                          ),
                                        ),
                                        const SizedBox(height: 12),
                                        Text(
                                          topDescription,
                                          style: TextStyle(
                                            color: Colors.grey.shade700,
                                            fontSize: MediaQuery.of(context).size.width > 600 ? 15 : 14,
                                          ),
                                        ),
                                      ],
                                    ),
                                  );
                                },
                              ),
                              const SizedBox(height: 24),
                              // All Predictions
                              Text(
                                'All Predictions',
                                style: TextStyle(
                                  fontSize: MediaQuery.of(context).size.width > 600 ? 20 : 18,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.black87,
                                ),
                              ),
                              const SizedBox(height: 12),
                              Builder(
                                builder: (context) {
                                  // pair labels with probabilities and sort descending
                                  final pairs = List.generate(
                                    _labels.length,
                                    (i) =>
                                        MapEntry(_labels[i], _probabilities[i]),
                                  );
                                  pairs.sort(
                                    (a, b) => b.value.compareTo(a.value),
                                  );

                                  // cycling palette for the left label color / bar fill
                                  final palette = [
                                    Colors.deepPurple,
                                    Colors.blue,
                                    Colors.orange,
                                    Colors.pink,
                                    Colors.purple,
                                    Colors.teal,
                                  ];

                                  return Column(
                                    children: List.generate(pairs.length - 1, (
                                      index,
                                    ) {
                                      final i = index + 1;
                                      final label = pairs[i].key;
                                      final prob = pairs[i].value;
                                      final color = palette[i % palette.length];

                                      return Padding(
                                        padding: const EdgeInsets.symmetric(
                                          vertical: 8,
                                        ),
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Row(
                                              children: [
                                                // colored label text
                                                Expanded(
                                                  child: Text(
                                                    label,
                                                    style: TextStyle(
                                                      color: color,
                                                      fontWeight:
                                                          FontWeight.w600,
                                                    ),
                                                  ),
                                                ),

                                                // percentage pill
                                                Container(
                                                  padding:
                                                      const EdgeInsets.symmetric(
                                                        horizontal: 8,
                                                        vertical: 6,
                                                      ),
                                                  decoration: BoxDecoration(
                                                    color: color.withOpacity(
                                                      0.95,
                                                    ),
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                          8,
                                                        ),
                                                  ),
                                                  child: Text(
                                                    '${(prob * 100).toStringAsFixed(0)}%',
                                                    style: const TextStyle(
                                                      color: Colors.white,
                                                      fontWeight:
                                                          FontWeight.bold,
                                                    ),
                                                  ),
                                                ),
                                              ],
                                            ),
                                            const SizedBox(height: 8),
                                            ClipRRect(
                                              borderRadius:
                                                  BorderRadius.circular(8),
                                              child: LinearProgressIndicator(
                                                value: prob,
                                                minHeight: 18,
                                                valueColor:
                                                    AlwaysStoppedAnimation<
                                                      Color
                                                    >(color),
                                                backgroundColor: color
                                                    .withOpacity(0.12),
                                              ),
                                            ),
                                          ],
                                        ),
                                      );
                                    }),
                                  );
                                },
                              ),
                            ],
                          ),
                        )
                      else
                        const SizedBox(),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
