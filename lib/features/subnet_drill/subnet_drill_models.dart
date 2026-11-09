import 'dart:math';

enum SubnetQuestionType {
  networkAddress,
  broadcastAddress,
  usableHosts,
  subnetMask,
}

class SubnetDrillQuestion {
  final String questionText;
  final String ipWithCidr;
  final List<String> options;
  final String correctAnswer;
  final String explanation;
  final SubnetQuestionType type;

  const SubnetDrillQuestion({
    required this.questionText,
    required this.ipWithCidr,
    required this.options,
    required this.correctAnswer,
    required this.explanation,
    required this.type,
  });

  static final Random _rand = Random();

  static SubnetDrillQuestion generate({bool isIndonesian = true}) {
    // Prefix between /24 and /30
    final prefix = 24 + _rand.nextInt(7); // 24..30
    final o1 = 192;
    final o2 = 168;
    final o3 = _rand.nextInt(20);
    final o4 = 1 + _rand.nextInt(253);

    final ipInt = (o1 << 24) | (o2 << 16) | (o3 << 8) | o4;
    final maskInt = prefix == 0 ? 0 : (~0 << (32 - prefix)) & 0xFFFFFFFF;
    final netInt = (ipInt & maskInt) >>> 0;
    final bcastInt = (netInt | (~maskInt & 0xFFFFFFFF)) >>> 0;

    String intToIp(int val) {
      return '${(val >>> 24) & 0xFF}.${(val >>> 16) & 0xFF}.${(val >>> 8) & 0xFF}.${val & 0xFF}';
    }

    final netStr = intToIp(netInt);
    final bcastStr = intToIp(bcastInt);
    final maskStr = intToIp(maskInt);
    final usableCount = prefix >= 31 ? 0 : (1 << (32 - prefix)) - 2;

    final type = SubnetQuestionType.values[_rand.nextInt(SubnetQuestionType.values.length)];

    String qText = '';
    String correct = '';
    String explanation = '';
    Set<String> optionSet = {};

    switch (type) {
      case SubnetQuestionType.networkAddress:
        qText = isIndonesian
            ? 'Tentukan Network Address dari:'
            : 'Determine Network Address for:';
        correct = netStr;
        explanation = isIndonesian
            ? 'Network Address = $netStr (Host bits diset ke 0)'
            : 'Network Address = $netStr (Host bits set to 0)';
        optionSet.add(correct);
        // Distractors
        final fakeNet1 = intToIp((netInt + (1 << (32 - prefix))) & 0xFFFFFFFF);
        final fakeNet2 = intToIp((netInt - (1 << (32 - prefix))) & 0xFFFFFFFF);
        final fakeNet3 = intToIp(netInt | 1);
        optionSet.addAll([fakeNet1, fakeNet2, fakeNet3, bcastStr]);
        break;

      case SubnetQuestionType.broadcastAddress:
        qText = isIndonesian
            ? 'Tentukan Broadcast Address dari:'
            : 'Determine Broadcast Address for:';
        correct = bcastStr;
        explanation = isIndonesian
            ? 'Broadcast Address = $bcastStr (Host bits diset ke 1)'
            : 'Broadcast Address = $bcastStr (Host bits set to 1)';
        optionSet.add(correct);
        final fakeBcast1 = intToIp((bcastInt - 1) & 0xFFFFFFFF);
        final fakeBcast2 = intToIp((bcastInt + (1 << (32 - prefix))) & 0xFFFFFFFF);
        optionSet.addAll([netStr, fakeBcast1, fakeBcast2]);
        break;

      case SubnetQuestionType.usableHosts:
        qText = isIndonesian
            ? 'Berapa jumlah usable host untuk prefix:'
            : 'How many usable hosts for prefix:';
        correct = '$usableCount';
        explanation = isIndonesian
            ? 'Rumus 2^(32-$prefix) - 2 = $usableCount host'
            : 'Formula 2^(32-$prefix) - 2 = $usableCount hosts';
        optionSet.add(correct);
        optionSet.add('${usableCount + 2}');
        optionSet.add('${max(1, (usableCount + 2) ~/ 2 - 2)}');
        optionSet.add('${(usableCount + 2) * 2 - 2}');
        break;

      case SubnetQuestionType.subnetMask:
        qText = isIndonesian
            ? 'Tentukan Subnet Mask desimal untuk prefix:'
            : 'Determine decimal Subnet Mask for prefix:';
        correct = maskStr;
        explanation = isIndonesian
            ? 'Prefix /$prefix setara dengan subnet mask $maskStr'
            : 'Prefix /$prefix corresponds to subnet mask $maskStr';
        optionSet.add(correct);
        optionSet.add('255.255.255.0');
        final otherPrefix = prefix > 24 ? prefix - 1 : prefix + 1;
        final fakeMask = intToIp((~0 << (32 - otherPrefix)) & 0xFFFFFFFF);
        optionSet.add(fakeMask);
        optionSet.add('255.255.255.254');
        break;
    }

    final optionsList = optionSet.take(4).toList();
    while (optionsList.length < 4) {
      optionsList.add('192.168.1.${_rand.nextInt(254)}');
    }
    optionsList.shuffle(_rand);

    return SubnetDrillQuestion(
      questionText: qText,
      ipWithCidr: type == SubnetQuestionType.usableHosts || type == SubnetQuestionType.subnetMask
          ? '/$prefix'
          : '$o1.$o2.$o3.$o4/$prefix',
      options: optionsList,
      correctAnswer: correct,
      explanation: explanation,
      type: type,
    );
  }
}

