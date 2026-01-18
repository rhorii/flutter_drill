import 'package:flutter/material.dart';

/// 画面サイズに基づくレスポンシブサイズ計算ユーティリティ
class ResponsiveSizes {
  final double screenWidth;
  final double screenHeight;

  const ResponsiveSizes({
    required this.screenWidth,
    required this.screenHeight,
  });

  /// BuildContextから生成
  factory ResponsiveSizes.of(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    return ResponsiveSizes(
      screenWidth: size.width,
      screenHeight: size.height,
    );
  }

  /// 画面の短辺
  double get shortestSide =>
      screenWidth < screenHeight ? screenWidth : screenHeight;

  /// 問題テキストのフォントサイズ (画面短辺の25%)
  double get questionFontSize => (shortestSide * 0.25).clamp(48.0, 256.0);

  /// 回答フィールドのフォントサイズ (画面短辺の20%)
  double get answerFontSize => (shortestSide * 0.20).clamp(40.0, 256.0);

  /// 一覧画面タイトルのフォントサイズ (画面短辺の8%)
  double get listTitleFontSize => (shortestSide * 0.08).clamp(24.0, 64.0);

  /// ボタンテキストのフォントサイズ (画面短辺の8%)
  double get buttonFontSize => (shortestSide * 0.08).clamp(24.0, 64.0);

  /// 水平パディング (画面短辺の5%)
  double get horizontalPadding => shortestSide * 0.05;

  /// ボタンパディング (画面短辺の3%)
  double get buttonPadding => shortestSide * 0.03;

  /// スペーサー高さ (画面短辺の5%)
  double get spacerHeight => shortestSide * 0.05;
}
