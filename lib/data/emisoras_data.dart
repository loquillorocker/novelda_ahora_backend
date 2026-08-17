import '../models/emisora.dart';

class EmisorasData {
  static const List<Emisora> emisoras = [
    Emisora(
      id: 'rne',
      nombre: 'RNE',
      descripcion:
      'Radio Nacional de España. Información, actualidad y entretenimiento.',
      tipo: TipoEmisora.publica,
      cobertura: CoberturaEmisora.nacional,
      urlWeb: 'https://www.rtve.es/play/radio/rne/',
      urlStreaming:
      'https://rtvelivestream.rtve.es/rtvesec/rne/rne_r1_main.m3u8',
    ),

    Emisora(
      id: 'rne_clasica',
      nombre: 'RNE Clásica',
      descripcion: 'Música clásica y cultura.',
      tipo: TipoEmisora.cultural,
      cobertura: CoberturaEmisora.nacional,
      urlWeb: 'https://www.rtve.es/play/radio/radio-clasica/',
      urlStreaming:
      'https://rtvelivestream.rtve.es/rtvesec/rne/rne_r2_main.m3u8',
    ),

    Emisora(
      id: 'rne_3',
      nombre: 'RNE 3',
      descripcion: 'Música, cultura y actualidad.',
      tipo: TipoEmisora.cultural,
      cobertura: CoberturaEmisora.nacional,
      urlWeb: 'https://www.rtve.es/play/radio/radio-3/',
      urlStreaming: 'https://rtvelivestream.rtve.es/rtvesec/rne/rne_r3_main.m3u8',
    ),

    Emisora(
      id: 'cope_alicante',
      nombre: 'COPE Alicante',
      descripcion: 'Información y actualidad de Alicante y provincia.',
      tipo: TipoEmisora.informativa,
      cobertura: CoberturaEmisora.provincial,
      localidad: 'Alicante',
      urlWeb: 'https://www.cope.es/directos/alicante',
      urlStreaming:
      'https://flucast09-h-cloud.flumotion.com/cope/net1.mp3',
    ),

    Emisora(
      id: 'radio_alicante_ser',
      nombre: 'Radio Alicante SER',
      descripcion: 'Actualidad de Alicante y provincia.',
      tipo: TipoEmisora.informativa,
      cobertura: CoberturaEmisora.provincial,
      localidad: 'Alicante',
      urlWeb: 'https://cadenaser.com/radio-alicante/',
      urlStreaming:
      'https://playerservices.streamtheworld.com/api/livestream-redirect/SER_ALICANTE.mp3',
    ),

    Emisora(
      id: 'radio_elda',
      nombre: 'Radio Elda SER',
      descripcion: 'Actualidad del Medio Vinalopó.',
      tipo: TipoEmisora.local,
      cobertura: CoberturaEmisora.comarcal,
      localidad: 'Elda',
      urlWeb: 'https://cadenaser.com/radio-elda/',
      urlStreaming:
      'https://playerservices.streamtheworld.com/api/livestream-redirect/SER_ASO_ELDA.mp3',
    ),

    Emisora(
      id: 'radio_aspe',
      nombre: 'Radio Aspe',
      descripcion: 'Radio local del Medio Vinalopó.',
      tipo: TipoEmisora.local,
      cobertura: CoberturaEmisora.local,
      localidad: 'Aspe',
      urlWeb: 'https://valledelasuvas.es/',
      urlStreaming:
      'http://streaming.enantena.com:8000/radioaspe128.mp3',
    ),

    Emisora(
      id: 'radio_novelda',
      nombre: 'Radio Novelda',
      descripcion: 'Radio local de Novelda.',
      tipo: TipoEmisora.local,
      cobertura: CoberturaEmisora.local,
      localidad: 'Novelda',
      urlWeb: 'https://www.noveldaradio.es/',
    ),

    Emisora(
      id: 'onda_cero_alicante',
      nombre: 'Onda Cero Alicante',
      descripcion: 'Información y actualidad de Alicante y provincia.',
      tipo: TipoEmisora.informativa,
      cobertura: CoberturaEmisora.provincial,
      localidad: 'Alicante',
      urlWeb: 'https://www.ondacero.es/emisoras/comunidad-valenciana/alicante/',
      urlStreaming:
      'https://radio-atres-live.ondacero.es/api/livestream-redirect/OC_ALICANTEAAC.m3u8',
    ),

    Emisora(
      id: 'los40',
      nombre: 'LOS40',
      descripcion: 'Música y entretenimiento.',
      tipo: TipoEmisora.musical,
      cobertura: CoberturaEmisora.nacional,
      urlWeb: 'https://los40.com/',
      urlStreaming:
      'https://playerservices.streamtheworld.com/api/livestream-redirect/Los40.mp3',
    ),

    Emisora(
      id: 'cadena_100',
      nombre: 'Cadena 100',
      descripcion: 'Música y entretenimiento.',
      tipo: TipoEmisora.musical,
      cobertura: CoberturaEmisora.nacional,
      urlWeb: 'https://www.cadena100.es/',
      urlStreaming:
      'https://cadena100-cope.flumotion.com/playlist.m3u8',
    ),

    Emisora(
      id: 'radio_marca',
      nombre: 'Radio Marca',
      descripcion: 'Información deportiva y actualidad.',
      tipo: TipoEmisora.informativa,
      cobertura: CoberturaEmisora.nacional,
      urlWeb: 'https://www.marca.com/radio.html',
      urlStreaming:
      'https://playerservices.streamtheworld.com/api/livestream-redirect/RADIOMARCA_NACIONAL.mp3',
    ),
  ];
}