import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:casi/features/enrollment/domain/entities/ethics.dart';

class EthicsModel extends Ethics {
  const EthicsModel({
    required super.version,
    required super.title,
    required super.body,
    required super.updatedAt,
  });

  factory EthicsModel.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final d = doc.data()!;
    final ts = d['updatedAt'];
    return EthicsModel(
      version: doc.id,
      title: d['title'] as String,
      body: d['body'] as String,
      updatedAt: ts is Timestamp ? ts.toDate() : DateTime.now(),
    );
  }
}
