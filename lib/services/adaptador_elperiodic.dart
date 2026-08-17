import '../models/noticia.dart';
import 'rss_service.dart';

class AdaptadorElPeriodico {
static const String fuenteId = 'elperiodic_novelda';
static const String fuenteNombre = 'El Periódico';

List<Noticia> convertir(List<NoticiaRss> items) {
return items.map(_convertirItem).toList();
}

Noticia _convertirItem(NoticiaRss item) {
return Noticia(
id: _generarId(item.url),
titulo: item.titulo,
resumen: item.resumen ?? '',
contenido: null,
tipo: TipoContenido.noticia,
categoria: _detectarCategoria(item.titulo),
fuenteId: fuenteId,
fuenteNombre: fuenteNombre,
urlOriginal: item.url,
imagenUrl: null,
videoUrl: null,
fechaPublicacion:
item.fechaPublicacion ?? DateTime.now(),
fechaCaptura: DateTime.now(),
autor: item.autor,
ubicacion: 'Novelda',
destacada: false,
activa: true,
etiquetas: const [],
);
}

String _generarId(String url) {
return Uri.encodeComponent(url);
}

CategoriaNoticia _detectarCategoria(String titulo) {
final texto = titulo.toLowerCase();

if (_contiene(texto, [
'fiesta',
'fiestas',
'moros',
'cristianos',
'pregón',
'pregona',
])) {
return CategoriaNoticia.fiestas;
}

if (_contiene(texto, [
'fútbol',
'futbol',
'deporte',
'corredores',
'carrera',
'santuario',
])) {
return CategoriaNoticia.deportes;
}

if (_contiene(texto, [
'policía',
'policia',
'guardia civil',
'detenido',
'detiene',
'accidente',
'herida',
'herido',
'suceso',
'robo',
])) {
return CategoriaNoticia.sucesos;
}

if (_contiene(texto, [
'ayuntamiento',
'municipal',
'pleno',
'concejal',
'alcalde',
'alcaldesa',
])) {
return CategoriaNoticia.politica;
}

if (_contiene(texto, [
'festival',
'cine',
'música',
'musica',
'cultura',
'revista',
'teatro',
])) {
return CategoriaNoticia.cultura;
}

if (_contiene(texto, [
'salud',
'sanidad',
'hospital',
'médico',
'medico',
'farmacia',
])) {
return CategoriaNoticia.salud;
}

if (_contiene(texto, [
'comercio',
'comercio local',
'empresa',
'empresas',
'economía',
'economia',
])) {
return CategoriaNoticia.economia;
}

if (_contiene(texto, [
'colegio',
'educación',
'educacion',
'instituto',
'universidad',
])) {
return CategoriaNoticia.educacion;
}

return CategoriaNoticia.actualidad;
}

bool _contiene(String texto, List<String> palabras) {
return palabras.any(texto.contains);
}
}
