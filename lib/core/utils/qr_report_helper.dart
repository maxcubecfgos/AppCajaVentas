import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../../domain/models/daily_summary.dart';

class QrReportHelper {
  QrReportHelper._();

  static String serializeSummary(DailySummary summary) {
    final dateFormat = DateFormat('yyyy-MM-dd');
    final breakdown = summary.breakdown
        .take(10)
        .map(
          (item) => {
            'n': item.productName,
            'q': item.quantitySold,
            's': item.subtotal,
          },
        )
        .toList();

    final data = {
      'd': dateFormat.format(summary.date),
      't': summary.totalIncome,
      'c': summary.transactionCount,
      'b': breakdown,
    };

    return jsonEncode(data);
  }

  static Widget buildQr(String data) {
    return Container(
      width: 280,
      height: 280,
      color: Colors.white,
      child: QrImageView(
        data: data,
        version: QrVersions.auto,
        size: 280,
        backgroundColor: Colors.white,
        gapless: true,
        errorStateBuilder: (context, error) {
          return Center(
            child: Text(
              'Error al generar QR: ${error.toString()}',
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.red),
            ),
          );
        },
      ),
    );
  }
}
