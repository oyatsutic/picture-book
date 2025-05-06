import 'dart:developer';
import 'package:flutter/material.dart';

void console(List<dynamic> params) {
  for (var param in params) {
    log('$param =========================================');
  }
}
