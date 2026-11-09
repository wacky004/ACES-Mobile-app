import 'package:sembast_web/sembast_web.dart';

Future<Database> openAppDatabase() async =>
    databaseFactoryWeb.openDatabase('cpe_reviewer.db');
