import 'package:flutter/material.dart';

class AppTheme {
  /// Cor padrão do sistema caso a instituição não tenha uma cor cadastrada (Fallback)
  static const Color defaultPrimaryColor = Color(0xFF1E88E5); // Azul Padrão

  /// Função que gera o tema visual customizado em tempo de execução.
  /// Converte uma string hexadecimal (ex: "#FF5733") em uma cor real do Flutter.
  static ThemeData generateTheme({String? hexColor}) {
    Color primaryColor = defaultPrimaryColor;

    // Se o banco de dados retornar uma cor válida, converte texto para Cor
    if (hexColor != null && hexColor.isNotEmpty) {
      try {
        // Limpa o caractere '#' se ele vier na string
        final cleanHex = hexColor.replaceAll('#', '');
        // Converte a string base 16 para o formato ARGB inteiro que o Flutter exige
        primaryColor = Color(int.parse('FF$cleanHex', radix: 16));
      } catch (e) {
        // Se houver algum erro de digitação no banco, usamos a cor padrão para o app não crashar
        primaryColor = defaultPrimaryColor;
      }
    }

    // Retorna o objeto de tema completo com base na cor escolhida
    return ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: primaryColor,
        primary: primaryColor,
        brightness: Brightness.light,
      ),
      // Customização global dos botões do aplicativo para seguirem o padrão visual
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryColor,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
      ),
      // Customização das caixas de texto (Inputs) do formulário
      inputDecorationTheme: InputDecorationTheme(
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        focusedBorder: OutlineInputBorder(
          borderSide: BorderSide(color: primaryColor, width: 2),
          borderRadius: BorderRadius.circular(8),
        ),
      ),
    );
  }
}