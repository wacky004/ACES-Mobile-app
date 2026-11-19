import 'package:flutter/material.dart';

import '../../core/theme.dart';
import 'web_learning_resource.dart';

const String _protocolExplorerUrl = String.fromEnvironment(
  'PROTOCOL_EXPLORER_URL',
  defaultValue: 'https://protocol-explorer-alpha.vercel.app/',
);

const String _electronics101Url = String.fromEnvironment(
  'ELECTRONICS_101_URL',
  defaultValue: 'https://electronics-101-six.vercel.app/',
);

const String _learnArduinoUrl = String.fromEnvironment(
  'LEARN_ARDUINO_URL',
  defaultValue: 'https://learn-arduino-red.vercel.app/',
);

const List<WebLearningResource> webLearningResources = [
  WebLearningResource(
    id: 'protocol-explorer',
    title: 'Protocol Explorer',
    tagline: 'Networking, packet by packet',
    description:
        '39 interactive networking lessons with animated packets and '
        'byte-level inspection.',
    url: _protocolExplorerUrl,
    lessonSummary: '39 lessons · 20 languages',
    icon: Icons.lan_rounded,
    accent: AppColors.blue,
    about:
        'Interactive networking lessons with animated packet journeys and '
        'byte-level inspection. Loads the live public website.',
  ),
  WebLearningResource(
    id: 'electronics-101',
    title: 'Electronics 101',
    tagline: 'Circuits on a 3D workbench',
    description:
        '48 hands-on electronics lessons, from basic circuits to sensors, '
        'on an interactive 3D bench.',
    url: _electronics101Url,
    lessonSummary: '48 lessons · 3D',
    icon: Icons.memory_rounded,
    accent: AppColors.amber,
    is3D: true,
    about:
        'A 3D electronics course covering circuits, resistors, LEDs, '
        'capacitors, switches, transistors, and sensors. Loads the live '
        'public website.',
  ),
  WebLearningResource(
    id: 'learn-arduino',
    title: 'Learn Arduino',
    tagline: 'Wire, code, and run',
    description:
        '16 beginner Arduino lessons on a 3D Uno board with a code editor '
        'and virtual simulator.',
    url: _learnArduinoUrl,
    lessonSummary: '16 lessons · 3D simulator',
    icon: Icons.developer_board_rounded,
    accent: AppColors.coral,
    is3D: true,
    about:
        'A 3D Arduino course covering LEDs, buttons, sensors, motors, and '
        'a project build, with code examples and a virtual simulator. Loads '
        'the live public website.',
  ),
];
