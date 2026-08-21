import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Mode d'affichage courant (clair/sombre), basculable par l'utilisateur.
final themeModeProvider = StateProvider<ThemeMode>((ref) => ThemeMode.light);
