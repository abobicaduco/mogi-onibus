/// Modelos de dados dos horários.

class SchedulesData {
  final String dataVersao;
  final String geradoEm;
  final String fonte;
  final List<BusLine> linhas;

  SchedulesData({
    required this.dataVersao,
    required this.geradoEm,
    required this.fonte,
    required this.linhas,
  });

  factory SchedulesData.fromJson(Map<String, dynamic> j) {
    return SchedulesData(
      dataVersao: (j['data_versao'] ?? '') as String,
      geradoEm: (j['gerado_em'] ?? '') as String,
      fonte: (j['fonte'] ?? '') as String,
      linhas: ((j['linhas'] ?? []) as List)
          .map((e) => BusLine.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }
}

class BusLine {
  final String linha;
  final String nome;
  final String titulo;
  final String pontoA;
  final String pontoB;
  final String sentido;
  final String dias;
  final String empresa;
  final String obs;

  /// horarios[diaTipo] = { 'ida': [...], 'volta': [...] }
  final Map<String, Map<String, List<String>>> horarios;

  BusLine({
    required this.linha,
    required this.nome,
    required this.titulo,
    required this.pontoA,
    required this.pontoB,
    required this.sentido,
    required this.dias,
    required this.empresa,
    required this.obs,
    required this.horarios,
  });

  factory BusLine.fromJson(Map<String, dynamic> j) {
    final raw = (j['horarios'] ?? {}) as Map<String, dynamic>;
    final parsed = <String, Map<String, List<String>>>{};
    raw.forEach((dia, dirs) {
      final m = <String, List<String>>{};
      (dirs as Map<String, dynamic>).forEach((d, list) {
        m[d] = (list as List).map((e) => e.toString()).toList();
      });
      parsed[dia] = m;
    });
    return BusLine(
      linha: (j['linha'] ?? '') as String,
      nome: (j['nome'] ?? '') as String,
      titulo: (j['titulo'] ?? '') as String,
      pontoA: (j['ponto_a'] ?? '') as String,
      pontoB: (j['ponto_b'] ?? '') as String,
      sentido: (j['sentido'] ?? '') as String,
      dias: (j['dias'] ?? '') as String,
      empresa: (j['empresa'] ?? '') as String,
      obs: (j['obs'] ?? '') as String,
      horarios: parsed,
    );
  }

  bool matches(String query) {
    final q = query.toLowerCase().trim();
    if (q.isEmpty) return true;
    return linha.toLowerCase().contains(q) ||
        nome.toLowerCase().contains(q) ||
        titulo.toLowerCase().contains(q) ||
        pontoA.toLowerCase().contains(q) ||
        pontoB.toLowerCase().contains(q);
  }
}
