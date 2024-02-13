import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:image/image.dart' as img;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:uiblock/uiblock.dart';
import 'package:camera_platform_interface/camera_platform_interface.dart';
import 'package:appranti_360/utils.dart';
import 'package:http/http.dart' as http;

var baseUrl = 'http://127.0.0.1:5000/';

class Appranti360CameraPage extends StatefulWidget {
  const Appranti360CameraPage({super.key});

  @override
  State<Appranti360CameraPage> createState() => _Appranti360CameraPageState();
}

class _Appranti360CameraPageState extends State<Appranti360CameraPage> {
  // Caméra initialisée
  bool _initialized = false;

  //
  List<CameraDescription> _cameras = <CameraDescription>[];

  //
  int _cameraId = -1;

  //
  String _cameraInfo = 'Unknown';

  //
  int _cameraIndex = 0;

  //
  final ResolutionPreset _resolutionPreset = ResolutionPreset.veryHigh;

  //
  StreamSubscription<CameraErrorEvent>? _errorStreamSubscription;

  //
  StreamSubscription<CameraClosingEvent>? _cameraClosingStreamSubscription;

  //
  Size? _previewSize;

  //
  late ScaffoldMessengerState _scaffoldMessengerState;

  // L'image à analyser
  Uint8List? _imageBytes;

  //
  final String _patronGetResultInference = patronGetResultInference;

  // La prédiction sous forme de masque
  late Uint8List _mask;

  // Afficher ou non le mask
  var _afficherMask = true;

  // Génération du mask complété
  var _generationMaskComplete = false;

  @override
  void initState() {
    super.initState();
    WidgetsFlutterBinding.ensureInitialized();
    _fetchCameras();
  }

  @override
  void dispose() {
    _disposeCurrentCamera();

    super.dispose();
  }

  /// Fetches list of available cameras from camera_windows plugin.
  Future<void> _fetchCameras() async {
    String cameraInfo;
    List<CameraDescription> cameras = <CameraDescription>[];

    int cameraIndex = 0;
    try {
      cameras = await CameraPlatform.instance.availableCameras();
      if (cameras.isEmpty) {
        cameraInfo = 'No available cameras';
      } else {
        cameraIndex = _cameraIndex % cameras.length;
        cameraInfo = 'Found camera: ${cameras[cameraIndex].name}';
      }
    } on PlatformException catch (e) {
      cameraInfo = 'Failed to get cameras: ${e.code}: ${e.message}';
    }

    if (mounted) {
      setState(() {
        _cameraIndex = cameraIndex;
        _cameras = cameras;
        _cameraInfo = cameraInfo;
      });
    }
  }

  /// Initializes the camera on the device.
  Future<void> _initializeCamera() async {
    assert(!_initialized);

    if (_cameras.isEmpty) {
      return;
    }

    int cameraId = -1;
    try {
      final int cameraIndex = _cameraIndex % _cameras.length;
      final CameraDescription camera = _cameras[cameraIndex];

      cameraId = await CameraPlatform.instance.createCamera(
        camera,
        _resolutionPreset,
      );

      unawaited(_errorStreamSubscription?.cancel());
      _errorStreamSubscription = CameraPlatform.instance.onCameraError(cameraId).listen(_onCameraError);

      unawaited(_cameraClosingStreamSubscription?.cancel());
      _cameraClosingStreamSubscription = CameraPlatform.instance.onCameraClosing(cameraId).listen(_onCameraClosing);

      final Future<CameraInitializedEvent> initialized = CameraPlatform.instance.onCameraInitialized(cameraId).first;

      await CameraPlatform.instance.initializeCamera(
        cameraId,
      );

      final CameraInitializedEvent event = await initialized;
      _previewSize = Size(
        event.previewWidth,
        event.previewHeight,
      );

      if (mounted) {
        setState(() {
          _initialized = true;
          _cameraId = cameraId;
          _cameraIndex = cameraIndex;
          _cameraInfo = 'Capturing camera: ${camera.name}';
        });
      }
    } on CameraException catch (e) {
      try {
        if (cameraId >= 0) {
          await CameraPlatform.instance.dispose(cameraId);
        }
      } on CameraException catch (e) {
        debugPrint('Failed to dispose camera: ${e.code}: ${e.description}');
      }

      // Reset state.
      if (mounted) {
        setState(() {
          _initialized = false;
          _cameraId = -1;
          _cameraIndex = 0;
          _previewSize = null;
          _cameraInfo = 'Failed to initialize camera: ${e.code}: ${e.description}';
        });
      }
    }
  }

  void _resetAnalyse() {
    setState(() {
      _mask = Uint8List(0);
      _imageBytes = null;
    });
    _afficherMask = false;
  }

  void _onCameraError(CameraErrorEvent event) {
    if (mounted) {
      _showInSnackBar('Erreur: ${event.description}');

      // Dispose camera on camera error as it can not be used anymore.
      _disposeCurrentCamera();
      _fetchCameras();
    }
  }

  void _onCameraClosing(CameraClosingEvent event) {
    if (mounted) {
      _showInSnackBar('Caméra fermée');
    }
  }

  Future<void> _disposeCurrentCamera() async {
    if (_cameraId >= 0 && _initialized) {
      _afficherMask = false;
      _mask = Uint8List(0);
      try {
        await CameraPlatform.instance.dispose(_cameraId);

        if (mounted) {
          setState(() {
            _initialized = false;
            _cameraId = -1;
            _previewSize = null;
            _cameraInfo = 'Camera fermée';
            _imageBytes = null;
          });
        }
      } on CameraException catch (e) {
        if (mounted) {
          setState(() {
            _cameraInfo = 'Impossible de fermer la caméra: ${e.code}: ${e.description}';
          });
        }
      }
    }
  }

  void _showInSnackBar(String message, {int duration = 3}) {
    _scaffoldMessengerState.showSnackBar(SnackBar(
      content: Text(message),
      duration: Duration(seconds: duration),
    ));
  }

  Widget _buildPreview() {
    return CameraPlatform.instance.buildPreview(_cameraId);
  }

  Future<void> _getInference(String jobId) async {
    // Va chercher la réponse
    var ready = 0;
    while (0 == ready) {
      final theUrl2 = _patronGetResultInference;
      final response2 = await http.post(Uri.parse(theUrl2), body: jsonEncode({'job_id': jobId}), headers: {'Content-Type': 'application/json'});
      if (response2.statusCode != 200) {
        throw Exception('Failed to load $theUrl2');
      }
      var payloadInference = A360InferenceDO.fromJson(jsonDecode(response2.body) as Map<String, dynamic>);
      jobId = payloadInference.jobId;
      ready = payloadInference.ready;
      if (0 == ready) {
        await Future.delayed(const Duration(milliseconds: 333));
      } else {
        _mask = payloadInference.mask;
      }
    }
  }

  Future<String> _uploadImage() async {
    // Encode image bytes as base64
    String base64Image = base64Encode(_imageBytes!);

    // Create JSON payload
    Map<String, dynamic> payload = {
      'image': base64Image,
    };

    // Convert payload to JSON
    String jsonPayload = jsonEncode(payload);

    // Send the JSON payload via HTTP POST
    try {
      final theUrl = '${baseUrl}posteinformatique/do_inference_with_image';
      var response = await http.post(
        Uri.parse(theUrl),
        headers: {'Content-Type': 'application/json'},
        body: jsonPayload,
      );

      // Check the response status
      if (response.statusCode != 200) {
        _showInSnackBar('Failed to load $theUrl');
      }
      var payloadInference = A360InferenceDO.fromJson(jsonDecode(response.body) as Map<String, dynamic>);
      var jobId = payloadInference.jobId;
      return jobId;
    } catch (error) {
      _showInSnackBar('Error uploading image: $error');
    }

    return "response";
  }

  Future<void> _decodeRotateEncode() async {
    // Assuming 'imageBytes' is the byte array of the captured image.
    img.Image? image = img.decodeImage(_imageBytes!);

    // // Get the size of the image
    // int width = image!.width;
    // int height = image!.height;
    //
    // // Print or use the width and height as needed
    // print('Image Width: $width');
    // print('Image Height: $height');

    // Rotate the image by 180 degrees
    img.Image rotatedImage = img.flip(image!, direction: img.FlipDirection.horizontal);

    _imageBytes = img.encodePng(image);
  }

  Future<void> _takePicture(BuildContext context) async {
    try {
      UIBlock.block(context);

      _generationMaskComplete = false;
      _afficherMask = false;
      _showInSnackBar('Analyse en cours...', duration: 1);
      // Future.delayed(const Duration(milliseconds: 999), () {});

      final XFile file = await CameraPlatform.instance.takePicture(_cameraId);

      _imageBytes = await file.readAsBytes();
      // // Create a File object from the XFile path.
      // File file2 = File(file.path);
      // Use the delete method to delete the file.
      await File(file.path).delete();

      // await _decodeRotateEncode();

      final String jobId = await _uploadImage();

      await _getInference(jobId);

      setState(() {
        _imageBytes;
        _mask;
      });
      _generationMaskComplete = true;
      _afficherMask = true;
    } finally {
      // call unblock after blockui to dissmiss
      UIBlock.unblock(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    _scaffoldMessengerState = ScaffoldMessenger.of(context);
    const double aHeight = 768;
    const double aWidth = 1024;
    return LayoutBuilder(builder: (context, constraints) {
      return ListView(children: [
        if (_initialized && _cameraId > 0 && _previewSize != null)
          Padding(
            padding: const EdgeInsets.symmetric(
              vertical: 10,
            ),
            child: Stack(alignment: Alignment.center, children: [
              Container(
                constraints: const BoxConstraints(
                  maxHeight: aHeight,
                  maxWidth: aWidth,
                ),
                child: AspectRatio(
                  aspectRatio: _previewSize!.width / _previewSize!.height,
                  child: _imageBytes == null
                      ? _buildPreview()
                      : Image.memory(
                          _imageBytes!,
                          fit: BoxFit.fitHeight,
                        ),
                  ),
              ),
              if (_afficherMask && _generationMaskComplete)
                Container(
                  constraints: const BoxConstraints(
                    maxHeight: aHeight,
                    maxWidth: aWidth,
                  ),
                  child: ColorFiltered(
                    colorFilter: ColorFilter.mode(
                      Colors.transparent.withOpacity(0.5), // 0.5 means 50% transparency
                      BlendMode.dstATop,
                    ),
                    child: Image.memory(
                      _mask,
                      fit: BoxFit.fitHeight,
                    ),
                  ),
                ),
            ]),
          ),
        if (_cameras.isEmpty)
          ElevatedButton(
            onPressed: _fetchCameras,
            child: const Text('Recherche des caméras disponibles'),
          ),
        if (_cameras.isNotEmpty)
          Row(mainAxisAlignment: MainAxisAlignment.center, children: <Widget>[
            ElevatedButton(
              onPressed: _initialized ? _disposeCurrentCamera : _initializeCamera,
              child: Text(_initialized ? 'Fermeture de la caméra' : 'Ouverture de la caméra'),
            ),
            const SizedBox(width: 5),
            ElevatedButton(
              onPressed: _initialized ? () => _takePicture(context) : null,
              child: const Text('Détection d\'anomalies'),
            ),
            const SizedBox(width: 5),
            ElevatedButton(
              onPressed: _initialized && null!=_imageBytes
                  ? () {
                      setState(() {
                        if (_afficherMask) {
                          _afficherMask = false;
                        } else {
                          _afficherMask = true;
                        }
                      });
                    }
                  : null,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _afficherMask ? const Icon(Icons.visibility_off) : const Icon(Icons.visibility), // Icon(Icons.star), // Your icon
                  const SizedBox(width: 8.0), // Adjust the spacing between icon and text
                  _afficherMask ? const Text('Cacher anomalies') : const Text('Afficher anomalies'),
                ],
              ),
            ),
            const SizedBox(width: 5),
            ElevatedButton(
              onPressed: _initialized && null!=_imageBytes ? _resetAnalyse : null,
              child: const Text('Remise à zéro'),
            ),
          ]),
      ]);
    });
  }
}
