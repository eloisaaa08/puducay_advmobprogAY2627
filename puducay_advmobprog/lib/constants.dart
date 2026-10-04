import 'package:flutter_dotenv/flutter_dotenv.dart';

var host = dotenv.env['HOST'];

// Demo DummyJSON user ID used as the cart owner for Firebase accounts, which have no numeric ID.
const int currentUserId = 2;
