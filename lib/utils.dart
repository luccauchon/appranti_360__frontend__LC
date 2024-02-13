import 'dart:convert';
import 'dart:typed_data';
import 'dart:io';

// const baseUrl = 'http://10.0.0.215:5000/';
const baseUrl = 'http://127.0.0.1:5000/';

// Patron du url pour obtenir les résultats d'une inférence
const String patronGetResultInference = '${baseUrl}posteinformatique/get_inference';

class Config {
  String serverAddress;

  Config({required this.serverAddress});

  factory Config.fromMap(Map<String, dynamic> map) {
    return Config(
      serverAddress: map['server_address'],
    );
  }
}

Future<Config> readConfig() async {
  File configFile = File('assets/config.json');
  if (!configFile.existsSync()) {
    throw FileSystemException("Config file doesn't exist!");
  }

  String contents = await configFile.readAsString();
  Map<String, dynamic> json = jsonDecode(contents);
  return Config.fromMap(json);
}

class A360InferenceDO {
  final String jobId;
  final int ready;
  final Uint8List mask;

  const A360InferenceDO({
    required this.jobId,
    required this.ready,
    required this.mask,
  });

  factory A360InferenceDO.fromJson(Map<String, dynamic> myJson) {
    List<String> decodeJsonStringToList(String jsonString) {
      List<dynamic> dynamicList = json.decode(jsonString);
      List<String> stringList = dynamicList.cast<String>();
      return stringList;
    }
    Uint8List decodeJson3DNumpyArrayToUint8List(List mask){
      // Extract the nested list from the decoded data
      List<List<List<int>>> nestedList = (mask as List).map<List<List<int>>>((list) {
        return (list as List).map<List<int>>((innerList) {
          return (innerList as List).cast<int>();
        }).toList();
      }).toList();

      // Flatten the nested list into a 1D list
      List<int> flattenedList = nestedList.expand((innerList) => innerList.expand((list) => list)).toList();

      // Convert the 1D list to Uint8List
      Uint8List uint8List = Uint8List.fromList(flattenedList);

      return uint8List;
    }
    Uint8List decodeJson1DNumpyArrayToUint8List(List mask){
      // Extract the image data from the JSON map
      List<int> imageData = List<int>.from(mask);

      // Convert the image data to Uint8List
      Uint8List uint8List = Uint8List.fromList(imageData);

      return uint8List;
    }
    Uint8List decodeJsonBase64StringToUint8List(String base64String){
      // Decode the base64 string to a Uint8List
      Uint8List uint8List = base64Decode(base64String);
      return uint8List;
    }
    return switch (myJson) {
      {
      'job_id': String jobId,
      'result_ready': int ready,
      'mask': String the_mask,
      } =>
          A360InferenceDO(
            jobId: jobId,
            ready: ready,
            mask: decodeJsonBase64StringToUint8List(the_mask),
          ),
      _ => throw const FormatException('Failed to load'),
    };
  }
}