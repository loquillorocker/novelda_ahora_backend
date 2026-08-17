import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/noticia.dart';

class FirestoreNoticiasService {
  final FirebaseFirestore _firestore =
      FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> get _noticias =>
      _firestore.collection('noticias');

  Future<void> guardarNoticia(Noticia noticia) async {
    await _noticias.doc(noticia.id).set(
      noticia.toMap(),
    );
  }

  Future<void> actualizarNoticia(Noticia noticia) async {
    await _noticias.doc(noticia.id).update(
      noticia.toMap(),
    );
  }

  Future<void> eliminarNoticia(String id) async {
    await _noticias.doc(id).delete();
  }

  Future<Noticia?> obtenerNoticia(String id) async {
    final documento = await _noticias.doc(id).get();

    if (!documento.exists || documento.data() == null) {
      return null;
    }

    return Noticia.fromMap(
      documento.data()!,
    );
  }

  Future<List<Noticia>> obtenerNoticias({
    int limite = 20,
  }) async {
    final snapshot = await _noticias
        .where(
      'activa',
      isEqualTo: true,
    )
        .where(
      'tipo',
      isEqualTo: TipoContenido.noticia.name,
    )
        .orderBy(
      'fechaPublicacion',
      descending: true,
    )
        .limit(limite)
        .get();

    return snapshot.docs
        .map(
          (documento) => Noticia.fromMap(
        documento.data(),
      ),
    )
        .toList();
  }

  Stream<List<Noticia>> escucharNoticias({
    int limite = 20,
  }) {
    return _noticias
        .where(
      'activa',
      isEqualTo: true,
    )
        .where(
      'tipo',
      isEqualTo: TipoContenido.noticia.name,
    )
        .orderBy(
      'fechaPublicacion',
      descending: true,
    )
        .limit(limite)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
          .map(
            (documento) => Noticia.fromMap(
          documento.data(),
        ),
      )
          .toList(),
    );
  }

  Stream<List<Noticia>> escucharVideos({
    int limite = 20,
  }) {
    return _noticias
        .where(
      'activa',
      isEqualTo: true,
    )
        .where(
      'tipo',
      isEqualTo: TipoContenido.video.name,
    )
        .orderBy(
      'fechaPublicacion',
      descending: true,
    )
        .limit(limite)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
          .map(
            (documento) => Noticia.fromMap(
          documento.data(),
        ),
      )
          .toList(),
    );
  }

  Future<Noticia?> obtenerNoticiaDestacada() async {
    final snapshot = await _noticias
        .where(
      'activa',
      isEqualTo: true,
    )
        .where(
      'destacada',
      isEqualTo: true,
    )
        .orderBy(
      'fechaPublicacion',
      descending: true,
    )
        .limit(1)
        .get();

    if (snapshot.docs.isEmpty) {
      return null;
    }

    return Noticia.fromMap(
      snapshot.docs.first.data(),
    );
  }

  Future<List<Noticia>> obtenerNoticiasPorCategoria(
      CategoriaNoticia categoria, {
        int limite = 3,
      }) async {
    final snapshot = await _noticias
        .where(
      'activa',
      isEqualTo: true,
    )
        .where(
      'categoria',
      isEqualTo: categoria.name,
    )
        .orderBy(
      'fechaPublicacion',
      descending: true,
    )
        .limit(limite)
        .get();

    return snapshot.docs
        .map(
          (documento) => Noticia.fromMap(
        documento.data(),
      ),
    )
        .toList();
  }
}