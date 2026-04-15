import 'package:flutter/material.dart';
import '../../offline/entities/table_entity.dart';

const Color kTableEmpty = Color(0xFF94A3B8);
const Color kTableActive = Color(0xFF4ADE80);
const Color kTableWaiting = Color(0xFFFBBF24);
const Color kTableServed = Color(0xFF60A5FA);
const Color kTableReserved = Color(0xFFA78BFA);

Color tableStatusColor(TableStatus s) {
  switch (s) {
    case TableStatus.empty:
      return kTableEmpty;
    case TableStatus.active:
      return kTableActive;
    case TableStatus.waiting:
      return kTableWaiting;
    case TableStatus.served:
      return kTableServed;
    case TableStatus.reserved:
      return kTableReserved;
  }
}

String tableStatusLabel(TableStatus s) {
  switch (s) {
    case TableStatus.empty:
      return 'Empty';
    case TableStatus.active:
      return 'Active';
    case TableStatus.waiting:
      return 'Waiting';
    case TableStatus.served:
      return 'Served';
    case TableStatus.reserved:
      return 'Reserved';
  }
}

IconData tableStatusIcon(TableStatus s) {
  switch (s) {
    case TableStatus.empty:
      return Icons.chair_outlined;
    case TableStatus.active:
      return Icons.restaurant_rounded;
    case TableStatus.waiting:
      return Icons.access_time_rounded;
    case TableStatus.served:
      return Icons.check_circle_outline_rounded;
    case TableStatus.reserved:
      return Icons.bookmark_rounded;
  }
}
