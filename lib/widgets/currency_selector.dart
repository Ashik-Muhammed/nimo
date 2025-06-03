import 'package:flutter/material.dart';

class CurrencySelector extends StatefulWidget {
  final String initialCurrency;
  final ValueChanged<String> onCurrencyChanged;
  final Map<String, double>? exchangeRates;

  const CurrencySelector({
    Key? key,
    this.initialCurrency = 'USD',
    required this.onCurrencyChanged,
    this.exchangeRates,
  }) : super(key: key);

  @override
  State<CurrencySelector> createState() => _CurrencySelectorState();
}

class _CurrencySelectorState extends State<CurrencySelector> {
  late String _selectedCurrency;
  late Map<String, double> _exchangeRates;

  @override
  void initState() {
    super.initState();
    _selectedCurrency = widget.initialCurrency;
    _exchangeRates = widget.exchangeRates ?? {
      'USD': 1.0,
      'EUR': 0.92,
      'GBP': 0.79,
      'JPY': 144.50,
      'AUD': 1.51,
      'CAD': 1.35,
      'CNY': 7.23,
      'INR': 83.12,
    };
  }

  @override
  Widget build(BuildContext context) {
    return DropdownButtonFormField<String>(
      value: _selectedCurrency,
      decoration: const InputDecoration(
        labelText: 'Currency',
        border: OutlineInputBorder(),
      ),
      items: _exchangeRates.keys
          .map<DropdownMenuItem<String>>((String currency) {
            return DropdownMenuItem<String>(
              value: currency,
              child: Text(currency),
            );
          })
          .toList(),
      onChanged: (value) {
        if (value != null) {
          setState(() {
            _selectedCurrency = value;
          });
          widget.onCurrencyChanged(value);
        }
      },
    );
  }
}
