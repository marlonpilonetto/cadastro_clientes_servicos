import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'db_helper.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(CadastroApp());
}

class CadastroApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Cadastro de Clientes e Serviços',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        fontFamily: 'Roboto',
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            padding: EdgeInsets.symmetric(vertical: 16, horizontal: 24),
          ),
        ),
        inputDecorationTheme: InputDecorationTheme(
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          contentPadding: EdgeInsets.symmetric(vertical: 12, horizontal: 16),
        ),
      ),
      debugShowCheckedModeBanner: false,
      home: HomeScreen(),
    );
  }
}

class HomeScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Cadastro de Clientes e Serviços')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => CadastroClienteScreen()),
                );
              },
              child: Text('Cadastro de Clientes'),
            ),
            SizedBox(height: 16),
            ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => CadastroServicoScreen()),
                );
              },
              child: Text('Cadastro de Serviços'),
            ),
          ],
        ),
      ),
    );
  }
}

class CadastroClienteScreen extends StatefulWidget {
  @override
  _CadastroClienteScreenState createState() => _CadastroClienteScreenState();
}

class _CadastroClienteScreenState extends State<CadastroClienteScreen> {
  final TextEditingController nomeController = TextEditingController();
  final TextEditingController telefoneController = TextEditingController();
  final TextEditingController enderecoController = TextEditingController();

  List<Map<String, dynamic>> clientes = [];

  @override
  void initState() {
    super.initState();
    _carregarClientes();
  }

  Future<void> _carregarClientes() async {
    final db = await DBHelper.initDb();
    final dados = await db.query('clientes');
    setState(() {
      clientes = dados;
    });
  }

  Future<void> _salvarCliente() async {
    if (nomeController.text.isEmpty ||
        telefoneController.text.isEmpty ||
        enderecoController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Preencha todos os campos corretamente.')),
      );
      return;
    }

    final db = await DBHelper.initDb();
    await db.insert('clientes', {
      'nome': nomeController.text,
      'telefone': telefoneController.text,
      'endereco': enderecoController.text,
    });

    nomeController.clear();
    telefoneController.clear();
    enderecoController.clear();

    _carregarClientes();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Cadastro de Clientes')),
      body: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextField(
              controller: nomeController,
              decoration: InputDecoration(labelText: 'Nome'),
            ),
            SizedBox(height: 12),
            TextField(
              controller: telefoneController,
              decoration: InputDecoration(labelText: 'Telefone'),
            ),
            SizedBox(height: 12),
            TextField(
              controller: enderecoController,
              decoration: InputDecoration(labelText: 'Endereço'),
            ),
            SizedBox(height: 16),
            ElevatedButton(
              onPressed: _salvarCliente,
              child: Text('Salvar Cliente'),
            ),
            Divider(height: 30),
            Expanded(
              child: ListView.builder(
                itemCount: clientes.length,
                itemBuilder: (context, index) {
                  final cliente = clientes[index];
                  return Card(
                    margin: EdgeInsets.symmetric(vertical: 8),
                    child: ListTile(
                      title: Text(cliente['nome']),
                      subtitle: Text('${cliente['telefone']} • ${cliente['endereco']}'),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class CadastroServicoScreen extends StatefulWidget {
  @override
  _CadastroServicoScreenState createState() => _CadastroServicoScreenState();
}

class _CadastroServicoScreenState extends State<CadastroServicoScreen> {
  final TextEditingController descricaoController = TextEditingController();
  final TextEditingController dataController = TextEditingController();
  final TextEditingController valorUnitarioController = TextEditingController();
  final TextEditingController horasController = TextEditingController();

  List<Map<String, dynamic>> servicos = [];
  List<Map<String, dynamic>> clientes = [];
  int? clienteIdSelecionado;

  @override
  void initState() {
    super.initState();
    _carregarServicos();
    _carregarClientes();
  }

  Future<void> _carregarServicos() async {
    final db = await DBHelper.initDb();
    final dados = await db.rawQuery('''
      SELECT s.*, c.nome AS cliente_nome FROM servicos s
      JOIN clientes c ON s.cliente_id = c.id
      ORDER BY s.data DESC
    ''');
    setState(() {
      servicos = dados;
    });
  }

  Future<void> _carregarClientes() async {
    final db = await DBHelper.initDb();
    final dados = await db.query('clientes');
    setState(() {
      clientes = dados;
    });
  }

  Future<void> _salvarServico() async {
    if (clienteIdSelecionado == null ||
        descricaoController.text.isEmpty ||
        dataController.text.isEmpty ||
        horasController.text.isEmpty ||
        valorUnitarioController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Preencha todos os campos corretamente.')),
      );
      return;
    }

    final db = await DBHelper.initDb();

    final horas = horasController.text;
    if (!RegExp(r'^\d{2}:\d{2}$').hasMatch(horas)) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Formato de horas inválido. Use HH:mm.')),
      );
      return;
    }

    final horasDecimal = double.parse(horas.split(':')[0]) + (double.parse(horas.split(':')[1]) / 60);

    final valorUnitario = double.tryParse(
      valorUnitarioController.text.replaceAll(RegExp(r'[^\d,]'), '').replaceAll(',', '.'),
    ) ?? 0;

    final valorTotal = horasDecimal * valorUnitario;

    await db.insert('servicos', {
      'cliente_id': clienteIdSelecionado,
      'descricao': descricaoController.text,
      'data': dataController.text,
      'horas': horas,
      'valor_unitario': valorUnitario,
      'valor_total': valorTotal,
    });

    descricaoController.clear();
    dataController.clear();
    valorUnitarioController.clear();
    clienteIdSelecionado = null;
    horasController.clear();

    _carregarServicos();
  }

  String _formatarValor(String input) {
    final numericString = input.replaceAll(RegExp(r'[^\d]'), '');
    final value = double.tryParse(numericString) ?? 0;
    final formattedValue = NumberFormat.currency(locale: 'pt_BR', symbol: 'R\$').format(value / 100);
    return formattedValue;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Cadastro de Serviços')),
      body: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextField(
              controller: descricaoController,
              decoration: InputDecoration(labelText: 'Descrição do Serviço'),
            ),
            SizedBox(height: 12),
            TextField(
              controller: dataController,
              keyboardType: TextInputType.number,
              inputFormatters: [
                FilteringTextInputFormatter.digitsOnly,
                LengthLimitingTextInputFormatter(10),
                TextInputFormatter.withFunction((oldValue, newValue) {
                  final text = newValue.text;
                  String formatted = text;

                  if (text.length >= 3) {
                    formatted = '${text.substring(0, 2)}/${text.substring(2)}';
                  }
                  if (text.length >= 6) {
                    formatted = '${text.substring(0, 2)}/${text.substring(2, 4)}/${text.substring(4)}';
                  }

                  if (formatted.length > 10) {
                    formatted = formatted.substring(0, 10);
                  }

                  return TextEditingValue(
                    text: formatted,
                    selection: TextSelection.collapsed(offset: formatted.length),
                  );
                }),
              ],
              decoration: InputDecoration(labelText: 'Data (dd/MM/yyyy)'),
            ),
            SizedBox(height: 12),
            TextField(
              controller: horasController,
              keyboardType: TextInputType.number,
              inputFormatters: [
                FilteringTextInputFormatter.digitsOnly,
                LengthLimitingTextInputFormatter(5),
                TextInputFormatter.withFunction((oldValue, newValue) {
                  final text = newValue.text;
                  String formatted = text;

                  if (text.length >= 3) {
                    formatted = '${text.substring(0, 2)}:${text.substring(2)}';
                  }

                  if (formatted.length > 5) {
                    formatted = formatted.substring(0, 5);
                  }

                  return TextEditingValue(
                    text: formatted,
                    selection: TextSelection.collapsed(offset: formatted.length),
                  );
                }),
              ],
              decoration: InputDecoration(labelText: 'Horas (HH:mm)'),
            ),
            SizedBox(height: 12),
            TextField(
              controller: valorUnitarioController,
              keyboardType: TextInputType.number,
              inputFormatters: [
                FilteringTextInputFormatter.digitsOnly,
                TextInputFormatter.withFunction((oldValue, newValue) {
                  final formatted = _formatarValor(newValue.text);
                  return TextEditingValue(
                    text: formatted,
                    selection: TextSelection.collapsed(offset: formatted.length),
                  );
                }),
              ],
              decoration: InputDecoration(labelText: 'Valor Unitário (R\$)'),
            ),
            SizedBox(height: 16),
            Text(
              'Selecione o Cliente:',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            DropdownButton<int>(
              value: clienteIdSelecionado,
              hint: Text('Selecione um cliente'),
              isExpanded: true,
              items: clientes.map((cliente) {
                return DropdownMenuItem<int>(
                  value: cliente['id'],
                  child: Text(cliente['nome']),
                );
              }).toList(),
              onChanged: (value) {
                setState(() {
                  clienteIdSelecionado = value;
                });
              },
            ),
            SizedBox(height: 16),
            ElevatedButton(
              onPressed: _salvarServico,
              child: Text('Salvar Serviço'),
            ),
            Divider(height: 30),
            Expanded(
              child: ListView.builder(
                itemCount: servicos.length,
                itemBuilder: (context, index) {
                  final s = servicos[index];
                  return Card(
                    margin: EdgeInsets.symmetric(vertical: 8),
                    child: ListTile(
                      title: Text(s['descricao']),
                      subtitle: Text(
                        '${s['cliente_nome']} • ${s['data']} • ${s['horas']}h x R\$${s['valor_unitario']}',
                      ),
                      trailing: Text('R\$${s['valor_total'].toStringAsFixed(2)}'),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
