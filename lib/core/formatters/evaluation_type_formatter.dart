import '../../domain/entities/evaluation.dart';

String evaluationTypeLabel(EvaluationType value) => switch (value) {
      EvaluationType.partial => 'Parcial',
      EvaluationType.recovery => 'Recuperatorio',
      EvaluationType.practicalWork => 'Trabajo práctico',
      EvaluationType.deliverable => 'Entregable',
      EvaluationType.project => 'Proyecto',
      EvaluationType.colloquium => 'Coloquio',
      EvaluationType.finalExam => 'Examen final',
      EvaluationType.other => 'Otro',
    };
