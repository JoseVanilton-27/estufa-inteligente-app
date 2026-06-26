import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';

void main() {
  runApp(const SmartGreenhouseApp());
}

class SmartGreenhouseApp extends StatelessWidget {
  const SmartGreenhouseApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: Brightness.dark,
        primarySwatch: Colors.green,
        scaffoldBackgroundColor: const Color(0xFF121212),
      ),
      home: const MainNavigation(),
    );
  }
}

class MainNavigation extends StatefulWidget {
  const MainNavigation({Key? key}) : super(key: key);

  @override
  State<MainNavigation> createState() => _MainNavigationState();
}

class _MainNavigationState extends State<MainNavigation> {
  int _selectedIndex = 0;

  static final List<Widget> _screens = [
    const DashboardScreen(),
    const HistoryScreen(),
    const SettingsScreen(),
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _selectedIndex,
        children: _screens,
      ),
      bottomNavigationBar: BottomNavigationBar(
        backgroundColor: const Color(0xFF1E1E1E),
        selectedItemColor: Colors.greenAccent,
        unselectedItemColor: Colors.grey,
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.dashboard), label: 'Status'),
          BottomNavigationBarItem(icon: Icon(Icons.history), label: 'Histórico'),
          BottomNavigationBarItem(icon: Icon(Icons.settings), label: 'Config'),
        ],
      ),
    );
  }
}

// --- TELA 1: DASHBOARD ---
class DashboardScreen extends StatefulWidget {
  const DashboardScreen({Key? key}) : super(key: key);

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  double temperatura = 24.5;
  double umidadeAr = 62.0;    
  double umidadeSolo = 72.0;
  bool bombaAtiva = false;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(seconds: 3), (timer) {
      final random = Random();
      if (!mounted) return;
      setState(() {
        temperatura = 22.0 + random.nextDouble() * 6; 
        umidadeAr = 55.0 + random.nextDouble() * 15;   
        
        if (umidadeSolo < 60.0) {
          bombaAtiva = true;
          umidadeSolo += 6.0; 
        } else if (umidadeSolo >= 80.0) {
          bombaAtiva = false;
          umidadeSolo -= 2.0; 
        } else {
          umidadeSolo += bombaAtiva ? 3.0 : -0.8;
        }
      });
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Estufa Inteligente IoT", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)), 
        centerTitle: true, 
        backgroundColor: Colors.transparent, 
        elevation: 0
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
        children: [
          Row(
            children: [
              Container(
                width: 10,
                height: 10,
                decoration: const BoxDecoration(color: Colors.greenAccent, shape: BoxShape.circle),
              ),
              const SizedBox(width: 8),
              const Text("Módulo ESP32 • Conectado", style: TextStyle(color: Colors.grey, fontSize: 13)),
            ],
          ),
          const SizedBox(height: 16),
          
          const Text("Leitura dos Sensores", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),

          _buildSensorCard("Temperatura do Ar", "${temperatura.toStringAsFixed(1)}°C", Icons.thermostat, Colors.orangeAccent),
          const SizedBox(height: 10),
          _buildSensorCard("Umidade do Ar", "${umidadeAr.toStringAsFixed(0)}%", Icons.cloud, Colors.lightBlueAccent),
          const SizedBox(height: 10),
          _buildSensorCard("Umidade do Solo", "${umidadeSolo.toStringAsFixed(0)}%", Icons.water_drop, Colors.blueAccent),
          
          const SizedBox(height: 20),
          const Text("Estado dos Atuadores", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),

          AnimatedContainer(
            duration: const Duration(milliseconds: 500),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFF1E1E1E), 
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: bombaAtiva ? Colors.blueAccent.withOpacity(0.8) : Colors.transparent,
                width: 2
              )
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.water, // ÍCONE CORRIGIDO AQUI
                      color: bombaAtiva ? Colors.blueAccent : Colors.grey, 
                      size: 28
                    ),
                    const SizedBox(width: 12),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text("Motobomba de Irrigação", style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 4),
                        Text(
                          bombaAtiva ? "Regando o cultivo..." : "Solo em nível ideal", 
                          style: TextStyle(color: Colors.grey[400], fontSize: 12)
                        ),
                      ],
                    ),
                  ],
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: bombaAtiva ? Colors.blueAccent.withOpacity(0.2) : Colors.white.withOpacity(0.05),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    bombaAtiva ? "LIGADA" : "DESLIGADA",
                    style: TextStyle(
                      color: bombaAtiva ? Colors.blueAccent : Colors.grey,
                      fontWeight: FontWeight.bold,
                      fontSize: 11,
                    ),
                  ),
                ),
              ],
            ),
          )
        ],
      ),
    );
  }

  Widget _buildSensorCard(String title, String value, IconData icon, Color color) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14), // COMPACTADO PARA EVITAR OVERFLOW
      decoration: BoxDecoration(
        color: const Color(0xFF1E1E1E), 
        borderRadius: BorderRadius.circular(12)
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 30),
          const SizedBox(width: 16),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start, 
            children: [
              Text(title, style: const TextStyle(color: Colors.grey, fontSize: 13)),
              const SizedBox(height: 2),
              Text(value, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
            ]
          ),
        ],
      ),
    );
  }
}

// --- TELA 2: HISTÓRICO ---
class HistoryScreen extends StatelessWidget {
  const HistoryScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Registro de Atividades", style: TextStyle(fontSize: 18)), backgroundColor: Colors.transparent, centerTitle: true),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildHistoryItem("Irrigação Concluída", "Hoje às 10:30", "Duração: 45s", Icons.check_circle, Colors.green),
          _buildHistoryItem("Alerta de Temperatura", "Hoje às 09:15", "Pico de 31°C atingido", Icons.warning, Colors.orange),
          _buildHistoryItem("Irrigação Concluída", "Ontem às 18:00", "Duração: 1min", Icons.check_circle, Colors.green),
          _buildHistoryItem("Sistema Reiniciado", "Ontem às 07:00", "Atualização de Firmware", Icons.sync, Colors.blue),
        ],
      ),
    );
  }

  Widget _buildHistoryItem(String title, String date, String desc, IconData icon, Color color) {
    return Card(
      color: const Color(0xFF1E1E1E),
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: Icon(icon, color: color),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
        subtitle: Text("$date\n$desc", style: const TextStyle(fontSize: 12)),
        isThreeLine: true,
      ),
    );
  }
}

// --- TELA 3: CONFIGURAÇÕES ---
class SettingsScreen extends StatelessWidget {
  const SettingsScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Configurações", style: TextStyle(fontSize: 18)), backgroundColor: Colors.transparent, centerTitle: true),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const Text("Tipo de Cultivo", style: TextStyle(color: Colors.greenAccent, fontWeight: FontWeight.bold, fontSize: 14)),
          const ListTile(title: Text("Planta Selecionada", style: TextStyle(fontSize: 14)), subtitle: Text("Samambaia (Solo Úmido)", style: TextStyle(fontSize: 12)), trailing: Icon(Icons.arrow_forward_ios, size: 14)),
          const Divider(),
          const Text("Parâmetros de Automação", style: TextStyle(color: Colors.greenAccent, fontWeight: FontWeight.bold, fontSize: 14)),
          ListTile(title: const Text("Umidade Mínima", style: TextStyle(fontSize: 14)), subtitle: const Text("60%"), trailing: Switch(value: true, onChanged: (v){})),
          ListTile(title: const Text("Umidade Máxima", style: TextStyle(fontSize: 14)), subtitle: const Text("80%"), trailing: Switch(value: true, onChanged: (v){})),
          const Divider(),
          const SizedBox(height: 20),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent),
            onPressed: () {}, 
            child: const Text("DESLIGAR ESTUFA (MANUAL)", style: TextStyle(fontSize: 12))
          )
        ],
      ), // SINTAXE FECHADA CORRETAMENTE AQUI
    );
  }
}
