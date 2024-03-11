import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';
import 'package:uiblock/uiblock.dart';
import 'package:carousel_slider/carousel_slider.dart';
import 'package:appranti_360/widgets/progressIndicator.dart';
import 'package:appranti_360/utils.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

Future<A360ImagesSurPosteInformatiqueDO> fetchA360Poste() async {
  final stopwatch = Stopwatch()..start();

  final theUrl = '${baseUrl}posteinformatique/listeimagespreview2';
  final response = await http.post(Uri.parse(theUrl), body: jsonEncode({'as_an_example': 0}), headers: {'Content-Type': 'application/json'});

  if (response.statusCode == 200) {
    var the_result = A360ImagesSurPosteInformatiqueDO.fromJson(jsonDecode(response.body) as Map<String, dynamic>);
    stopwatch.stop();
    print('Execution time to fetch A360Poste: ${stopwatch.elapsed}  ->  ${stopwatch.elapsed.inMilliseconds} ms');
    return the_result;
  } else {
    throw Exception('Failed to load $theUrl with batch number of 0');
  }
}

class A360ImagesSurPosteInformatiqueDO {
  final List<String> imagesName; // Pas utilisé
  final List<String> imagesUrl;
  final int batchSize; // Pas utilisé
  final int numberBatches;

  const A360ImagesSurPosteInformatiqueDO({
    required this.imagesName,
    required this.imagesUrl,
    required this.batchSize,
    required this.numberBatches,
  });

  factory A360ImagesSurPosteInformatiqueDO.fromJson(Map<String, dynamic> myJson) {
    List<String> decodeJsonStringToList(String jsonString) {
      List<dynamic> dynamicList = json.decode(jsonString);
      List<String> stringList = dynamicList.cast<String>();
      return stringList;
    }

    return switch (myJson) {
      {
        'images_name': String imagesName,
        'images_url': String imagesUrl,
        'batch_size': int batchSize,
        'number_batches': int numberBatches,
      } =>
        A360ImagesSurPosteInformatiqueDO(
          imagesName: decodeJsonStringToList(imagesName),
          imagesUrl: decodeJsonStringToList(imagesUrl),
          batchSize: batchSize,
          numberBatches: numberBatches,
        ),
      _ => throw const FormatException('Failed to load'),
    };
  }
}

class Appranti360PosteInformatiquePage extends StatefulWidget {
  final Config config;
  const Appranti360PosteInformatiquePage({super.key, required this.config});

  @override
  State<Appranti360PosteInformatiquePage> createState() => _Appranti360PosteInformatiquePageState(config: config);
}

class _Appranti360PosteInformatiquePageState extends State<Appranti360PosteInformatiquePage> {
  _Appranti360PosteInformatiquePageState({required this.config});
  final Config config;

  // String getBaseUrl(){
  //   final baseUrl = config.serverAddress;
  //   return baseUrl;
  // }

  // Le url de l'image affichée
  String _imageDisplayed = '${baseUrl}posteinformatique/get_image?imgid=0&magicnumber=1';

  // Patron du url pour obtenir une image
  final String _patronImageDisplayed = '${baseUrl}posteinformatique/get_image?imgid=19751222&magicnumber=1';

  // Patron du url pour demander une inférence
  final String _patronAskForInference = '${baseUrl}posteinformatique/get_image?imgid=19751222&magicnumber=1&modeleid=123';

  // Patron du url pour demander le nom du fichier de l'image
  final String _patronAskForImageName = '${baseUrl}posteinformatique/get_image_name?imgid=19751222&magicnumber=1';

  // Patron du url pour obtenir les résultats d'une inférence
  final String _patronGetResultInference = patronGetResultInference;

  // Le maximum pour le slider
  int _maxBatchValue = 999;

  // Des informations pour faire fonctionner la vue
  late Future<A360ImagesSurPosteInformatiqueDO> futureA360PosteInformatique3;

  // Pour le slider avec timeout
  double _sliderValue = 0;
  double _lastChangedValue = 0;
  Timer? _debounceTimer;
  String _fileNameAssociatedWithImage = "";

  // Numéro changeant pour modifier continuellement le URL pour que l'appel se fasse
  int _magicNumber = 1;

  // Accès au whatever that is
  late ScaffoldMessengerState _scaffoldMessengerState;

  // Afficher ou non le mask
  var _afficherMask = true;

  // Génération du mask complété
  var _generationMaskComplete = false;

  // Le mask
  late Uint8List _mask;

  // Débuggage
  var _pourDebug = false;

  late double _scale;
  late TransformationController _controller;

  // Define a list of items for the dropdown
  final List<String> defauts = ['Corrosion de l\'armature', 'Fissures polygonales', 'Désagrégation'];
  // Define a variable to store the selected item
  String defautSelectionne = 'Corrosion de l\'armature';

  // Sélection du model
  String selectedModel = 'Modèle 1'; // Initial selected value

  @override
  void initState() {
    super.initState();
    futureA360PosteInformatique3 = fetchA360Poste();
    _controller = TransformationController();
    _scale = 1.0;
  }

  void _get_name_img(slider_value) async {
    // await Future.delayed(Duration(milliseconds: 3333));
    final the_url = _patronAskForImageName.replaceFirst("imgid=19751222", "imgid=$slider_value");
    final response = await http.post(Uri.parse(the_url), body: jsonEncode({'as_an_example': 0}), headers: {'Content-Type': 'application/json'});
    if (response.statusCode != 200) {
      throw Exception('Failed to load $the_url');
    }
    var payload = jsonDecode(response.body);
    setState(() {
      _fileNameAssociatedWithImage = payload['filename'];
    });
  }

  void _sliderChanged(value) {
    setState(() {
      _sliderValue = value;
    });

    if (_debounceTimer != null && _debounceTimer!.isActive) {
      _debounceTimer!.cancel();
    }

    _debounceTimer = Timer(const Duration(milliseconds: 1000), () {
      if (_lastChangedValue != _sliderValue) {
        _lastChangedValue = _sliderValue;
        _generationMaskComplete = false;
        final slider_value = _sliderValue.toInt();
        // print('Calling onChanged after 1 second of inactivity: ${_sliderValue.toInt()}');
        String modifiedString = _patronImageDisplayed.replaceFirst("imgid=19751222", "imgid=${slider_value}");
        _magicNumber = 1;
        _get_name_img(slider_value);
        setState(() {
          _imageDisplayed = modifiedString;
          _afficherMask = false;
        });
      }
    });
  }

  void _nextImage() {
    setState(() {
      _sliderValue = (_sliderValue + 1) % _maxBatchValue;
      _sliderChanged(_sliderValue);
    });
  }

  void _previousImage() {
    setState(() {
      _sliderValue = (_sliderValue - 1) % _maxBatchValue;
      _sliderChanged(_sliderValue);
    });
  }

  Future<void> _detectionAnomalies2(BuildContext context, String selectedModel) async {
    try {
      // default
      UIBlock.block(context);

      final stopwatch = Stopwatch()..start();
      _generationMaskComplete = false;
      // Demande d'inférence
      String modifiedString = _patronAskForInference.replaceFirst("imgid=19751222", "imgid=${_sliderValue.toInt()}");
      modifiedString = modifiedString.replaceFirst('modeleid=123', 'modeleid=$selectedModel');
      modifiedString = modifiedString.replaceFirst('get_image', 'do_inference_for_image');
      _magicNumber = _magicNumber + 1;
      modifiedString = modifiedString.replaceFirst('magicnumber=1', 'magicnumber=$_magicNumber');
      final theUrl = modifiedString;
      // print(theUrl);
      final response = await http.post(Uri.parse(theUrl), body: jsonEncode({'as_an_example': 0}), headers: {'Content-Type': 'application/json'});
      if (response.statusCode != 200) {
        throw Exception('Failed to load $theUrl');
      }
      var payload_inference = A360InferenceDO.fromJson(jsonDecode(response.body) as Map<String, dynamic>);
      var jobId = payload_inference.jobId;

      // Va chercher la réponse
      var ready = 0;
      while (0 == ready) {
        final theUrl2 = _patronGetResultInference;
        // print(theUrl2);
        final response2 = await http.post(Uri.parse(theUrl2), body: jsonEncode({'job_id': jobId}), headers: {'Content-Type': 'application/json'});
        if (response2.statusCode != 200) {
          throw Exception('Failed to load $theUrl2');
        }
        payload_inference = A360InferenceDO.fromJson(jsonDecode(response2.body) as Map<String, dynamic>);
        jobId = payload_inference.jobId;
        ready = payload_inference.ready;
        if (0 == ready) {
          await Future.delayed(Duration(milliseconds: 333));
        }
      }
      // La réponse est reçue
      setState(() {
        _mask = payload_inference.mask;
      });
      _generationMaskComplete = true;
      setState(() {
        _afficherMask = true;
      });
      stopwatch.stop();
      print('Execution time to inference: ${stopwatch.elapsed}  ->  ${stopwatch.elapsed.inMilliseconds} ms');
    } finally {
      // call unblock after blockui to dissmiss
      UIBlock.unblock(context);
    }
  }

  void _onScaleUpdate(ScaleUpdateDetails details) {
    setState(() {
      _scale = _controller.value.getMaxScaleOnAxis();
    });
  }

  void _showInSnackBar(String message) {
    _scaffoldMessengerState.showSnackBar(SnackBar(
      content: Text(message),
      duration: const Duration(seconds: 1),
    ));
  }

  void _readCfg() async {
    Config config = await readConfig();
    _showInSnackBar("lkdj sdfahlksdhfajlkhasdjlkhasfjlkhasfjkhasd f");
  }

  void _empty(){}
  @override
  Widget build(BuildContext context) {
    _scaffoldMessengerState = ScaffoldMessenger.of(context);
    const double aHeight = 600;
    const double aWidth = 800;
    bool _isLoading = true;

    // _readCfg();
    return LayoutBuilder(builder: (context, constraints) {
      //final double maxWidth = constraints.maxWidth - 150; // Adjust for the width of other widgets
      //final double maxHeight = constraints.maxHeight - 150; // Adjust for the width of other widgets
      return Center(
        child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
          Expanded(
              child:Padding(
                padding: const EdgeInsets.all(10),
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    if (!_generationMaskComplete)
                      InteractiveViewer(
                        boundaryMargin: const EdgeInsets.all(0.0),
                        transformationController: _controller,
                        onInteractionUpdate: _onScaleUpdate,
                        minScale: 0.1,
                        maxScale: 10.0,
                        child: Image.network(_imageDisplayed),
                      ),
                    if (_pourDebug)
                      CustomPaint(
                        painter: MaskPainter(maskColor: Colors.black.withOpacity(0.5), text: 'Hello Luc, Masked Text!'),
                        child: SizedBox(
                          width: constraints.maxWidth,
                          height: constraints.maxHeight,
                        ),
                      ),
                    if (_generationMaskComplete)
                      InteractiveViewer(
                        boundaryMargin: const EdgeInsets.all(0.0),
                        minScale: 0.1,
                        maxScale: 10.0,
                        child: Stack(
                          children: [
                            Center(child: Image.network(_imageDisplayed,)),
                            if (_afficherMask)
                              Center(
                                child: ColorFiltered(
                                  colorFilter: ColorFilter.mode(
                                    Colors.transparent.withOpacity(0.5), // 0.5 means 50% transparency
                                    BlendMode.dstATop,
                                  ),
                                  child: Image.memory(_mask,
                                    fit: BoxFit.fitHeight,
                                    // width: double.infinity,
                                    // height: double.infinity,
                                    // width: aWidth, height: aHeight,
                                    //width: maxWidth, height: maxHeight,
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                  ],
                ),
              ),
              // Row(children: [
              //   Column(children: [
              //     Visibility(
              //         visible: true,
              //         child:Padding(padding: const EdgeInsets.all(8.0), child: ElevatedButton(onPressed: () => _empty(), child: const Text("Détection d'anomalies"))),
              //     ),
              //     Padding(padding: const EdgeInsets.all(8.0), child: DropdownButton<String>(
              //       // Define the dropdown value
              //       value: defautSelectionne,
              //       // Define the items for the dropdown
              //       items: defauts.map((String item) {
              //         return DropdownMenuItem<String>(
              //           value: item,
              //           child: Text(item),
              //         );
              //       }).toList(),
              //       // Define the onChanged callback
              //       onChanged: (String? newValue) {
              //       },
              //     )),
              //   ],),
              //
              // ],),
          ),
          Row(
            children: [
              const SizedBox(width: 5),
              ElevatedButton.icon(
                onPressed: _previousImage,
                icon: const Icon(Icons.remove_rounded),
                label: const Text(''),
              ),
              FutureBuilder<A360ImagesSurPosteInformatiqueDO>(
                  future: futureA360PosteInformatique3,
                  builder: (context, snapshot) {
                    if (snapshot.hasData) {
                      // https://stackoverflow.com/questions/72895710/convert-int-to-int-in-flutter
                      _maxBatchValue = snapshot.data?.numberBatches ?? 999;
                      return Expanded(
                        child: Slider(
                          value: _sliderValue,
                          onChanged: (value) => _sliderChanged(value),
                          min: 0,
                          max: _maxBatchValue.toDouble(),
                          activeColor: Colors.blue,
                        ),
                      );
                    } else if (snapshot.hasError) {
                      return Text('$snapshot.error');
                    }
                    // By default, show a loading spinner.
                    return const CircularProgressIndicator();
                  }),
              ElevatedButton.icon(
                onPressed: _nextImage,
                icon: const Icon(Icons.add_rounded),
                label: const Text(''),
              ),
              const SizedBox(width: 5),
              Text('${_sliderValue.toInt()}'),
              const SizedBox(width: 5),
              SelectableText('${_fileNameAssociatedWithImage}'),
              const SizedBox(width: 5),
              // ValueListenableBuilder(
              //   valueListenable: _fileNameAssociatedWithImage,
              //   builder: (context, value, child) {
              //     return Text(
              //       'Value: $value',
              //       style: TextStyle(fontSize: 24),
              //     );
              //   },
              // ),
            ],
          ),
          Row(
            children: [
              Padding(padding: const EdgeInsets.all(8.0), child: ElevatedButton(onPressed: () => _detectionAnomalies2(context, selectedModel), child: const Text("Détection d'anomalies"))),
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: ElevatedButton(
                  onPressed: () {
                    setState(() {
                      if (_afficherMask) {
                        _afficherMask = false;
                      } else {
                        _afficherMask = true;
                      }
                    });
                  },
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _afficherMask ? const Icon(Icons.visibility_off) : const Icon(Icons.visibility), // Icon(Icons.star), // Your icon
                      const SizedBox(width: 8.0), // Adjust the spacing between icon and text
                      _afficherMask ? const Text('Cacher anomalies') : const Text('Afficher anomalies'),
                    ],
                  ),
                ),
              ),
              Padding(padding: const EdgeInsets.all(8.0),
                      child: DropdownButton<String>(
                        value: selectedModel,
                        onChanged: (String? newValue) {
                          if (newValue != null) {
                            setState(() {
                              selectedModel = newValue;
                            });
                          }
                        },
                        items: <String>['Modèle 1', 'Option 2', 'Option 3', 'Option 4'].map<DropdownMenuItem<String>>((String value) {
                          return DropdownMenuItem<String>(
                            value: value,
                            child: Text(value),
                          );
                        }).toList(),
                    ),
              ),
            ],
          ),
        ]),
      );
    });
  }
}

class MaskPainter extends CustomPainter {
  final Color maskColor;
  final String text;

  MaskPainter({required this.maskColor, required this.text});

  @override
  void paint(Canvas canvas, Size size) {
    Paint paint = Paint()..color = maskColor;

    // Draw a rectangle as a mask
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), paint);

    paint = Paint()
      ..color = Colors.red
      ..style = PaintingStyle.stroke;

    // Draw text on the mask
    TextPainter textPainter = TextPainter(
      text: TextSpan(
        text: '$text',
        style: TextStyle(color: Colors.white, fontSize: 20.0),
      ),
      textDirection: TextDirection.ltr,
    );

    textPainter.layout();
    textPainter.paint(
      canvas,
      Offset(size.width / 2 - textPainter.width / 2, size.height / 2 - textPainter.height / 2),
    );

    // Define the mask path
    Path path = Path()
      ..moveTo(0, 0)
      ..lineTo(size.width, 0)
      ..lineTo(size.width, size.height * 0.5)
      ..lineTo(size.width * 0.5, size.height)
      ..lineTo(0, size.height)
      ..close();

    // Draw the mask
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) {
    return false;
  }
}
