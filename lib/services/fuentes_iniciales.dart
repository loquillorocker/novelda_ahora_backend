import '../models/fuente.dart';

class FuentesIniciales {
static const Fuente elPeriodico = Fuente(
id: 'elperiodic_novelda',
nombre: 'El Periódico',
tipo: TipoFuente.prensa,
url: 'https://www.elperiodic.com/novelda',
rssUrl: 'https://www.elperiodic.com/feed/rss_novelda.xml',
activa: true,
prioridad: 10,
);

static const List<Fuente> todas = [
elPeriodico,
];
}

