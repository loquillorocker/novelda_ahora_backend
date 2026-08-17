
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/fuente.dart';

class FirestoreFuentesService {
final FirebaseFirestore _firestore = FirebaseFirestore.instance;

CollectionReference<Map<String, dynamic>> get _fuentes =>
_firestore.collection('fuentes');

Future<void> guardarFuente(Fuente fuente) async {
await _fuentes.doc(fuente.id).set(fuente.toMap());
}

Future<void> actualizarFuente(Fuente fuente) async {
await _fuentes.doc(fuente.id).update(fuente.toMap());
}

Future<void> eliminarFuente(String id) async {
await _fuentes.doc(id).delete();
}

Future<Fuente?> obtenerFuente(String id) async {
final documento = await _fuentes.doc(id).get();

if (!documento.exists || documento.data() == null) {
return null;
}

return Fuente.fromMap(documento.data()!);
}

Future<List<Fuente>> obtenerFuentes() async {
final snapshot = await _fuentes
    .where('activa', isEqualTo: true)
    .orderBy('prioridad', descending: true)
    .get();

return snapshot.docs
    .map((documento) => Fuente.fromMap(documento.data()))
    .toList();
}

Stream<List<Fuente>> escucharFuentes() {
return _fuentes
    .where('activa', isEqualTo: true)
    .orderBy('prioridad', descending: true)
    .snapshots()
    .map(
(snapshot) => snapshot.docs
    .map((documento) => Fuente.fromMap(documento.data()))
    .toList(),
);
}
}

