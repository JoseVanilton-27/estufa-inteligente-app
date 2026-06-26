import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';

void main() {
  runApp(const SmartGreenhouseApp());
}

// ESTADO GLOBAL COMPARTILHADO
class GreenhouseData {
  static double temperatura = 24.5;
  static double umidadeAr = 62.0;    
  static double umidadeSolo = 72.0;
  static bool bombaAtiva = false;
  static bool coolerAtivo = false;
  static bool modoManualBomba = false; 
  
  // Limiares configuráveis pelo utilizador (Dinâmicos)
  static double limiteUmidadeMin = 60.0;
  static double limiteUmidadeMax = 80.0; 
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
  Timer? _globalTimer;

  @override
  void initState() {
    super.initState();
    _globalTimer = Timer.periodic(const Duration(seconds: 2), (timer) {
      final random = Random();
      if (!mounted) return;
      
      setState(() {
        // CORRIGIDO: Adicionado o prefixo GreenhouseData para atualizar o estado global
        GreenhouseData.temperatura = 22.0 + random.nextDouble() * 6; 
        GreenhouseData.umidadeAr = 55.0 + random.nextDouble() * 15;
        
        if (GreenhouseData.temperatura > 26.0) {
          GreenhouseData.coolerAtivo = true;
        } else {
          GreenhouseData.coolerAtivo = false;
        }

        // LÓGICA DA MOTOBOMBA COM OS DOIS LIMITES DINÂMICOS
        if (GreenhouseData.modoManualBomba) {
          GreenhouseData.bombaAtiva = true;
          GreenhouseData.umidadeSolo += 5.0;
        } else {
          if (GreenhouseData.umidadeSolo < GreenhouseData.limiteUmidadeMin) {
            GreenhouseData.bombaAtiva = true;
            GreenhouseData.umidadeSolo += 6.0; 
          } else if (GreenhouseData.umidadeSolo >= GreenhouseData.limiteUmidadeMax) {
            GreenhouseData.bombaAtiva = false;
            GreenhouseData.umidadeSolo -= 2.0; 
          } else {
            GreenhouseData.umidadeSolo += GreenhouseData.bombaAtiva ? 3.0 : -1.0;
          }
        }
        
        if (GreenhouseData.umidadeSolo > 100) GreenhouseData.umidadeSolo = 100;
        if (GreenhouseData.umidadeSolo < 0) GreenhouseData.umidadeSolo = 0;
      });
    });
  }

  @override
  void dispose() {
    _globalTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final List<Widget> screens = [
      DashboardScreen(onRefresh: () => setState(() {})),
      const HistoryScreen(),
      SettingsScreen(onChanged: () => setState(() {})),
    ];

    return Scaffold(
      body: IndexedStack(
        index: _selectedIndex,
        children: screens,
      ),
      bottomNavigationBar: BottomNavigationBar(
        backgroundColor: const Color(0xFF1E1E1E),
        selectedItemColor: Colors.greenAccent,
        unselectedItemColor: Colors.grey,
        currentIndex: _selectedIndex,
        onTap: (index) => setState(() => _selectedIndex = index),
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
class DashboardScreen extends StatelessWidget {
  final VoidCallback onRefresh;
  const DashboardScreen({Key? key, required this.onRefresh}) : super(key: key);

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
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    width: 10,
                    height: 10,
                    decoration: const BoxDecoration(color: Colors.greenAccent, shape: BoxShape.circle),
                  ),
                  const SizedBox(width: 8),
                  const Text("ESP32 • Monitoramento Ativo", style: TextStyle(color: Colors.grey, fontSize: 13)),
                ],
              ),
              Text(
                GreenhouseData.modoManualBomba ? "MODO MANUAL" : "MODO AUTO",
                style: TextStyle(color: GreenhouseData.modoManualBomba ? Colors.orangeAccent : Colors.greenAccent, fontSize: 11, fontWeight: FontWeight.bold),
              )
            ],
          ),
          const SizedBox(height: 16),
          
          const Text("Leitura dos Sensores", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),

          _buildSensorCard("Temperatura do Ar", "${GreenhouseData.temperatura.toStringAsFixed(1)}°C", Icons.thermostat, Colors.orangeAccent),
          const SizedBox(height: 10),
          _buildSensorCard("Umidade do Ar", "${GreenhouseData.umidadeAr.toStringAsFixed(0)}%", Icons.cloud, Colors.lightBlueAccent),
          const SizedBox(height: 10),
          
          _buildSensorCard(
            "Umidade do Solo (Alvo: ${GreenhouseData.limiteUmidadeMin.toStringAsFixed(0)}% a ${GreenhouseData.limiteUmidadeMax.toStringAsFixed(0)}%)", 
            "${GreenhouseData.umidadeSolo.toStringAsFixed(0)}%", 
            Icons.water_drop, 
            Colors.blueAccent
          ),
          
          const SizedBox(height: 24),
          const Text("Estado dos Atuadores", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),

          _buildAtuadorCard(
            title: "Motobomba de Irrigação",
            subtitle: GreenhouseData.bombaAtiva ? "Injetando água no solo..." : "Solo dentro dos limiares",
            isActive: GreenhouseData.bombaAtiva,
            icon: Icons.water,
            color: Colors.blueAccent,
            trailing: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: GreenhouseData.modoManualBomba ? Colors.orange : Colors.grey[800],
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8)
              ),
              onPressed: () {
                GreenhouseData.modoManualBomba = !GreenhouseData.modoManualBomba;
                if (!GreenhouseData.modoManualBomba) GreenhouseData.bombaAtiva = false;
                onRefresh(); 
              },
              child: Text(GreenhouseData.modoManualBomba ? "Parar" : "Regar", style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
            ),
          ),
          const SizedBox(height: 12),

          _buildAtuadorCard(
            title: "Sistema de Ventilação (Cooler)",
            subtitle: GreenhouseData.coolerAtivo ? "Exaurindo ar quente (+26°C)..." : "Temperatura estável",
            isActive: GreenhouseData.coolerAtivo,
            icon: Icons.wind_power,
            color: Colors.tealAccent,
            trailing: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: GreenhouseData.coolerAtivo ? Colors.tealAccent.withOpacity(0.2) : Colors.white.withOpacity(0.05),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                GreenhouseData.coolerAtivo ? "LIGADO" : "DESLIGADO",
                style: TextStyle(color: GreenhouseData.coolerAtivo ? Colors.tealAccent : Colors.grey, fontWeight: FontWeight.bold, fontSize: 11),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSensorCard(String title, String value, IconData icon, Color color) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(color: const Color(0xFF1E1E1E), borderRadius: BorderRadius.circular(12)),
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

  Widget _buildAtuadorCard({required String title, required String subtitle, required bool isActive, required IconData icon, required Color color, required Widget trailing}) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 400),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFF1E1E1E), 
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: isActive ? color.withOpacity(0.5) : Colors.transparent, width: 1.5)
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Icon(icon, color: isActive ? color : Colors.grey, size: 28),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 2),
                  Text(subtitle, style: TextStyle(color: Colors.grey[400], fontSize: 11)),
                ],
              ),
            ],
          ),
          trailing
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
          _buildHistoryItem("Exaustão Ativada", "Hoje às 11:12", "Cooler acionado por temperatura alta", Icons.wind_power, Colors.tealAccent),
          _buildHistoryItem("Limiares Atualizados", "Hoje às 10:45", "Nova janela operacional definida pelo utilizador", Icons.settings, Colors.greenAccent),
          _buildHistoryItem("Irrigação Automática", "Ontem às 18:00", "Solo atingiu limite mínimo", Icons.smart_toy, Colors.blueAccent),
          _buildHistoryItem("Sistema Conectado", "Ontem às 07:00", "Módulo ESP32 sincronizado via Wi-Fi", Icons.wifi, Colors.greenAccent),
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
class SettingsScreen extends StatefulWidget {
  final VoidCallback onChanged;
  const SettingsScreen({Key? key, required this.onChanged}) : super(key: key);

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Configurações", style: TextStyle(fontSize: 18)), backgroundColor: Colors.transparent, centerTitle: true),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const Text("Controle de Histerese do Solo", style: TextStyle(color: Colors.greenAccent, fontWeight: FontWeight.bold, fontSize: 14)),
          const SizedBox(height: 16),
          Card(
            color: const Color(0xFF1E1E1E),
            child: Padding(
              padding: const EdgeInsets.all(12.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // SLIDER 1: UMIDADE MÍNIMA
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text("Umidade Mínima (Ligar)", style: TextStyle(fontSize: 14)),
                      Text("${GreenhouseData.limiteUmidadeMin.toStringAsFixed(0)}%", style: const TextStyle(color: Colors.blueAccent, fontWeight: FontWeight.bold)),
                    ],
                  ),
                  Slider(
                    value: GreenhouseData.limiteUmidadeMin,
                    min: 30.0,
                    max: 65.0,
                    divisions: 7,
                    activeColor: Colors.blueAccent,
                    onChanged: (newValue) {
                      setState(() {
                        if (newValue < GreenhouseData.limiteUmidadeMax) {
                          GreenhouseData.limiteUmidadeMin = newValue;
                        }
                      });
                      widget.onChanged(); 
                    },
                  ),
                  const SizedBox(height: 12),
                  
                  // SLIDER 2: UMIDADE MÁXIMA
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text("Umidade Máxima (Desligar)", style: TextStyle(fontSize: 14)),
                      Text("${GreenhouseData.limiteUmidadeMax.toStringAsFixed(0)}%", style: const TextStyle(color: Colors.greenAccent, fontWeight: FontWeight.bold)),
                    ],
                  ),
                  Slider(
                    value: GreenhouseData.limiteUmidadeMax,
                    min: 70.0,
                    max: 95.0,
                    divisions: 5,
                    activeColor: Colors.greenAccent,
                    onChanged: (newValue) {
                      setState(() {
                        if (newValue > GreenhouseData.limiteUmidadeMin) {
                          GreenhouseData.limiteUmidadeMax = newValue;
                        }
                      });
                      widget.onChanged(); 
                    },
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    "A bomba liga quando o solo atinge a umidade mínima e desliga assim que atinge o limite máximo configurado.", 
                    style: TextStyle(color: Colors.grey, fontSize: 11)
                  ),
                ],
              ),
            ),
          ),
          const Divider(height: 32),
          const Text("Status Geral do Hardware", style: TextStyle(color: Colors.grey, fontSize: 13)),
          const ListTile(
            leading: Icon(Icons.memory, color: Colors.grey),
            title: Text("Placa Principal", style: TextStyle(fontSize: 14)),
            subtitle: Text("ESP32-WROOM-32D (NodeMCU)", style: TextStyle(fontSize: 12)),
          )
        ],
      ),
    );
  }
}
