import 'package:flutter/material.dart';
import 'package:brasil_fields/brasil_fields.dart';
import 'package:flag/flag.dart';

class PhoneInputWithFlags extends StatefulWidget {
  final TextEditingController controller;
  final String? labelText;
  final String? hintText;
  final Function(String)? onChanged;
  final String? Function(String?)? validator;
  final bool required;

  const PhoneInputWithFlags({
    super.key,
    required this.controller,
    this.labelText,
    this.hintText,
    this.onChanged,
    this.validator,
    this.required = false,
  });

  @override
  State<PhoneInputWithFlags> createState() => _PhoneInputWithFlagsState();
}

class _PhoneInputWithFlagsState extends State<PhoneInputWithFlags> {
  String selectedState = 'SP'; // Estado padrão
  
  // Lista de estados brasileiros
  final List<Map<String, String>> estados = [
    {'sigla': 'AC', 'nome': 'Acre'},
    {'sigla': 'AL', 'nome': 'Alagoas'},
    {'sigla': 'AP', 'nome': 'Amapá'},
    {'sigla': 'AM', 'nome': 'Amazonas'},
    {'sigla': 'BA', 'nome': 'Bahia'},
    {'sigla': 'CE', 'nome': 'Ceará'},
    {'sigla': 'DF', 'nome': 'Distrito Federal'},
    {'sigla': 'ES', 'nome': 'Espírito Santo'},
    {'sigla': 'GO', 'nome': 'Goiás'},
    {'sigla': 'MA', 'nome': 'Maranhão'},
    {'sigla': 'MT', 'nome': 'Mato Grosso'},
    {'sigla': 'MS', 'nome': 'Mato Grosso do Sul'},
    {'sigla': 'MG', 'nome': 'Minas Gerais'},
    {'sigla': 'PA', 'nome': 'Pará'},
    {'sigla': 'PB', 'nome': 'Paraíba'},
    {'sigla': 'PR', 'nome': 'Paraná'},
    {'sigla': 'PE', 'nome': 'Pernambuco'},
    {'sigla': 'PI', 'nome': 'Piauí'},
    {'sigla': 'RJ', 'nome': 'Rio de Janeiro'},
    {'sigla': 'RN', 'nome': 'Rio Grande do Norte'},
    {'sigla': 'RS', 'nome': 'Rio Grande do Sul'},
    {'sigla': 'RO', 'nome': 'Rondônia'},
    {'sigla': 'RR', 'nome': 'Roraima'},
    {'sigla': 'SC', 'nome': 'Santa Catarina'},
    {'sigla': 'SP', 'nome': 'São Paulo'},
    {'sigla': 'SE', 'nome': 'Sergipe'},
    {'sigla': 'TO', 'nome': 'Tocantins'},
  ];
  
  // Mapa de DDDs por estado
  final Map<String, List<String>> estadoDDDs = {
    'AC': ['68'],
    'AL': ['82'],
    'AP': ['96'],
    'AM': ['92', '97'],
    'BA': ['71', '73', '74', '75', '77'],
    'CE': ['85', '88'],
    'DF': ['61'],
    'ES': ['27', '28'],
    'GO': ['62', '64'],
    'MA': ['98', '99'],
    'MT': ['65', '66'],
    'MS': ['67'],
    'MG': ['31', '32', '33', '34', '35', '37', '38'],
    'PA': ['91', '93', '94'],
    'PB': ['83'],
    'PR': ['41', '42', '43', '44', '45', '46'],
    'PE': ['81', '87'],
    'PI': ['86', '89'],
    'RJ': ['21', '22', '24'],
    'RN': ['84'],
    'RS': ['51', '53', '54', '55'],
    'RO': ['69'],
    'RR': ['95'],
    'SC': ['47', '48', '49'],
    'SP': ['11', '12', '13', '14', '15', '16', '17', '18', '19'],
    'SE': ['79'],
    'TO': ['63'],
  };

  String _detectStateFromPhone(String phone) {
    String cleanPhone = phone.replaceAll(RegExp(r'\D'), '');
    if (cleanPhone.length >= 2) {
      String ddd = cleanPhone.substring(0, 2);
      for (String estado in estadoDDDs.keys) {
        if (estadoDDDs[estado]!.contains(ddd)) {
          return estado;
        }
      }
    }
    return 'SP'; // Padrão
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        // Flag do Brasil
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey.shade300),
            borderRadius: BorderRadius.circular(8),
          ),
          child: const Row(
            children: [
              Flag.fromString('BR', height: 20, width: 30),
              SizedBox(width: 4),
              Text('+55', style: TextStyle(fontSize: 16)),
            ],
          ),
        ),
        const SizedBox(width: 8),
        
        // Flag do Estado
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey.shade300),
            borderRadius: BorderRadius.circular(8),
          ),
          child: DropdownButton<String>(
            value: selectedState,
            underline: const SizedBox(),
            items: estados.map((estado) {
              return DropdownMenuItem<String>(
                value: estado['sigla'],
                child: Row(
                  children: [
                    const Icon(Icons.location_on, size: 16, color: Colors.blue),
                    const SizedBox(width: 4),
                    Text(estado['sigla']!, style: const TextStyle(fontSize: 14)),
                  ],
                ),
              );
            }).toList(),
            onChanged: (String? newValue) {
              setState(() {
                selectedState = newValue!;
              });
            },
          ),
        ),
        const SizedBox(width: 8),
        
        // Campo de telefone
        Expanded(
          child: TextFormField(
            controller: widget.controller,
            style: const TextStyle(fontSize: 16),
            decoration: InputDecoration(
              labelText: widget.labelText ?? 'Telefone',
              labelStyle: const TextStyle(fontSize: 16),
              hintText: widget.hintText ?? '(11) 99999-9999',
              border: const OutlineInputBorder(),
              contentPadding: const EdgeInsets.all(16),
            ),
            keyboardType: TextInputType.phone,
            inputFormatters: [
              TelefoneInputFormatter(),
            ],
            validator: widget.validator,
            onChanged: (value) {
              // Auto-detectar estado pelo DDD
              String detectedState = _detectStateFromPhone(value);
              if (detectedState != selectedState) {
                setState(() {
                  selectedState = detectedState;
                });
              }
              // Chamar o callback do widget pai SOMENTE se fornecido
              if (widget.onChanged != null) {
                widget.onChanged!(value);
              }
            },
          ),
        ),
      ],
    );
  }
} 
