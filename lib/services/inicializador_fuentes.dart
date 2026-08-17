import 'firestore_fuentes_service.dart';
import 'fuentes_iniciales.dart';

class InicializadorFuentes {
final FirestoreFuentesService _firestoreService;

InicializadorFuentes({
FirestoreFuentesService? firestoreService,
}) : _firestoreService =
firestoreService ?? FirestoreFuentesService();

Future<void> inicializar() async {
for (final fuente in FuentesIniciales.todas) {
await _firestoreService.guardarFuente(fuente);
}
}
}
