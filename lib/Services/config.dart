import 'dart:io';
import 'dart:developer';
import 'package:flutter/material.dart';

void console(List<dynamic> params) {
  for (var param in params) {
    log('$param =========================================');
  }
}

void listFilesInDirectory(String path) async {
  final dir = Directory(path);
  final List<FileSystemEntity> entities = await dir.list().toList();

  for (var entity in entities) {
    print(entity.path);
  }
}

// Usage after getting app directory