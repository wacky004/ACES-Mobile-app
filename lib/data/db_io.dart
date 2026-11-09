import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:sembast/sembast_io.dart';

Future<Database> openAppDatabase() async {
  final directory = await getApplicationDocumentsDirectory();
  final path = p.join(directory.path, 'cpe_reviewer.db');
  return databaseFactoryIo.openDatabase(path);
}
