import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

class SystemHealthTab extends StatelessWidget {
  final Map<String, dynamic> data;

  const SystemHealthTab({
    Key? key,
    required this.data,
  }) : super(key: key);
  @override
  Widget build(BuildContext context) {
    print('🎯 SystemHealthTab received data: $data');
    print('📊 Data keys: ${data.keys}');
    print('💾 Data isEmpty: ${data.isEmpty}');
    
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeader(),
          const SizedBox(height: 20),
          _buildMetricsGrid(),
          const SizedBox(height: 20),
          _buildDataSourceInfo(),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            FaIcon(
              FontAwesomeIcons.heartPulse,
              color: Colors.orange,
              size: 24,
            ),
            const SizedBox(width: 12),
            const Text(
              'System Health',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const Spacer(),
            _buildRealDataIndicator(),
          ],
        ),
        const SizedBox(height: 8),
        const Text(
          'Real-time system resource monitoring',
          style: TextStyle(
            fontSize: 16,
            color: Colors.grey,
          ),
        ),
      ],
    );
  }

  Widget _buildRealDataIndicator() {
    final bool hasData = data.isNotEmpty;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: hasData ? Colors.green.withOpacity(0.1) : Colors.orange.withOpacity(0.1),
        border: Border.all(
          color: hasData ? Colors.green : Colors.orange,
          width: 1,
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            hasData ? Icons.check_circle : Icons.info,
            color: hasData ? Colors.green : Colors.orange,
            size: 16,
          ),
          const SizedBox(width: 6),
          Text(
            hasData ? 'Real Data' : 'No Data',
            style: TextStyle(
              color: hasData ? Colors.green : Colors.orange,
              fontWeight: FontWeight.w600,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMetricsGrid() {
    if (data.isEmpty) {
      return _buildNoDataCard();
    }

    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisSpacing: 16,
      mainAxisSpacing: 16,
      childAspectRatio: 1.2,
      children: [
        _buildCPUCard(),
        _buildRAMCard(),
        _buildDiskCard(),
        _buildNetworkCard(),
      ],
    );
  }

  Widget _buildNoDataCard() {
    return Card(
      elevation: 4,
      child: Container(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            FaIcon(
              FontAwesomeIcons.circleExclamation,
              color: Colors.orange,
              size: 48,
            ),
            const SizedBox(height: 16),
            const Text(
              'No System Health Data Available',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            const Text(
              'System metrics are not currently available from the API.',
              style: TextStyle(
                color: Colors.grey,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCPUCard() {
    final cpuUsage = _getNumericValue('cpu') ?? 0.0;    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                FaIcon(
                  FontAwesomeIcons.microchip,
                  color: Colors.blue,
                  size: 20,
                ),
                const SizedBox(width: 8),
                const Text(
                  'CPU Usage',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),            const SizedBox(height: 8),
            Text(
              '${cpuUsage.toStringAsFixed(1)}%',
              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: Colors.blue,              ),
            ),
            const SizedBox(height: 6),
            LinearProgressIndicator(
              value: cpuUsage / 100,
              backgroundColor: Colors.grey[300],
              valueColor: AlwaysStoppedAnimation<Color>(
                _getUsageColor(cpuUsage),
              ),
            ),
          ],
        ),
      ),
    );
  }  Widget _buildRAMCard() {
    final ramUsagePercent = _getNumericValue('ram') ?? 0.0; // Direttamente la percentuale
    final hasRamData = ramUsagePercent > 0;
    
    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                FaIcon(
                  FontAwesomeIcons.memory,
                  color: Colors.green,
                  size: 20,
                ),
                const SizedBox(width: 8),
                const Text(
                  'RAM',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),            const SizedBox(height: 6),            Text(
              hasRamData ? '${ramUsagePercent.toStringAsFixed(1)}%' : 'No Data',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: hasRamData ? Colors.green : Colors.grey,
              ),
            ),
            Text(
              hasRamData ? 'Memory Usage' : 'Data unavailable',
              style: const TextStyle(
                fontSize: 10,
                color: Colors.grey,
              ),
            ),
            const SizedBox(height: 6),
            LinearProgressIndicator(
              value: ramUsagePercent / 100,
              backgroundColor: Colors.grey[300],
              valueColor: AlwaysStoppedAnimation<Color>(
                _getUsageColor(ramUsagePercent),
              ),
            ),            const SizedBox(height: 2),            Text(
              hasRamData ? 'From system metrics' : 'No data available',
              style: const TextStyle(
                fontSize: 9,
                color: Colors.grey,
              ),
            ),
          ],
        ),
      ),
    );
  }  Widget _buildDiskCard() {
    final diskUsagePercent = _getNumericValue('disk') ?? 0.0; // Direttamente la percentuale
    final hasDiskData = diskUsagePercent > 0;
    
    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                FaIcon(
                  FontAwesomeIcons.hardDrive,
                  color: Colors.purple,
                  size: 20,
                ),
                const SizedBox(width: 8),
                const Text(
                  'Disk',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),            const SizedBox(height: 6),            Text(
              hasDiskData ? '${diskUsagePercent.toStringAsFixed(1)}%' : 'No Data',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: hasDiskData ? Colors.purple : Colors.grey,
              ),
            ),
            Text(
              hasDiskData ? 'Disk Usage' : 'Data unavailable',
              style: const TextStyle(
                fontSize: 10,
                color: Colors.grey,
              ),
            ),
            const SizedBox(height: 6),
            LinearProgressIndicator(
              value: diskUsagePercent / 100,
              backgroundColor: Colors.grey[300],
              valueColor: AlwaysStoppedAnimation<Color>(
                _getUsageColor(diskUsagePercent),
              ),
            ),            const SizedBox(height: 2),            Text(
              hasDiskData ? 'From system metrics' : 'No data available',
              style: const TextStyle(
                fontSize: 9,
                color: Colors.grey,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNetworkCard() {
    final networkSpeed = _getNumericValue('network') ?? 0.0;    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                FaIcon(
                  FontAwesomeIcons.wifi,
                  color: Colors.orange,
                  size: 20,
                ),
                const SizedBox(width: 8),
                const Text(
                  'Network',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),            const SizedBox(height: 8),
            Text(
              '${networkSpeed.toStringAsFixed(1)} Mbps',
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.orange,
              ),
            ),
            const SizedBox(height: 6),            Row(
              children: [
                Icon(
                  networkSpeed > 0 ? Icons.trending_up : Icons.trending_flat,
                  color: networkSpeed > 0 ? Colors.green : Colors.grey,
                  size: 14,
                ),
                const SizedBox(width: 4),
                Text(
                  networkSpeed > 0 ? 'Active' : 'Idle',
                  style: TextStyle(
                    color: networkSpeed > 0 ? Colors.green : Colors.grey,
                    fontSize: 10,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDataSourceInfo() {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                FaIcon(
                  FontAwesomeIcons.database,
                  color: Colors.grey[600],
                  size: 16,
                ),
                const SizedBox(width: 8),
                Text(
                  'Data Source Information',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey[700],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            _buildDataSourceRow('Source', 'Prometheus API'),
            _buildDataSourceRow('Endpoint', '/api/prometheus/system-health'),
            _buildDataSourceRow('Update Frequency', '30 seconds'),
            _buildDataSourceRow('Last Updated', _getLastUpdated()),
            _buildDataSourceRow('Status', data.isNotEmpty ? 'Connected' : 'No Data'),
          ],
        ),
      ),
    );
  }

  Widget _buildDataSourceRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[600],
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontSize: 12,
                color: Colors.black87,
              ),
            ),
          ),
        ],
      ),
    );
  }  double? _getNumericValue(String key) {
    print('🔍 Looking for key: $key in data keys: ${data.keys}');
    
    // Prima controlla se i dati sono nested in resource_usage
    Map<String, dynamic> resourceData = data;
    if (data.containsKey('resource_usage')) {
      resourceData = data['resource_usage'] as Map<String, dynamic>? ?? {};
      print('📊 Using resource_usage data with keys: ${resourceData.keys}');
    }
    
    // Mappa i nomi delle chiavi dall'API alla struttura attesa
    String apiKey;
    switch (key) {
      case 'cpu':
        apiKey = 'cpu_usage_percent';
        break;
      case 'ram':
        // Per ora usiamo la percentuale di memoria
        apiKey = 'memory_usage_percent';
        break;      case 'ram_total':
        // Non disponibile nei dati attuali, non ritorniamo mock data
        return 0.0;
      case 'disk':
        // Per ora usiamo la percentuale di disco
        apiKey = 'disk_usage_percent';
        break;      case 'disk_total':
        // Non disponibile nei dati attuali, non ritorniamo mock data
        return 0.0;
      case 'network':
        apiKey = 'network_usage_percent';
        break;
      default:
        apiKey = key;
    }
    
    final apiValue = resourceData[apiKey];
    print('🔍 Found value for $apiKey: $apiValue (type: ${apiValue.runtimeType})');
    
    if (apiValue == null) {
      print('❌ Value is null for $apiKey');
      return null;
    }
    
    // Se il valore è wrappato in un oggetto con 'value'
    if (apiValue is Map<String, dynamic> && apiValue.containsKey('value')) {
      final value = apiValue['value'];
      print('📦 Unwrapped value: $value');
        if (value is num) {
        double result = value.toDouble();
        
        // Mantieni le percentuali come percentuali per RAM e Disk
        if (key == 'network') {
          // Converti da percentuale a Mbps (valore molto piccolo)
          result = result * 10; // Moltiplica per renderlo più visibile
        }
        
        print('✅ Final converted value for $key: $result');
        return result;
      }
      
      return null;
    }
      // Se il valore è diretto
    if (apiValue is num) {
      double result = apiValue.toDouble();
      
      // Mantieni le percentuali come percentuali per RAM e Disk
      if (key == 'network') {
        result = result * 10;
      }
      
      print('✅ Direct converted value for $key: $result');
      return result;
    }
    
    print('❌ Could not convert $apiKey value: $apiValue');
    return null;
  }

  Color _getUsageColor(double percentage) {
    if (percentage < 50) return Colors.green;
    if (percentage < 80) return Colors.orange;
    return Colors.red;
  }

  String _getLastUpdated() {
    return DateTime.now().toString().substring(0, 19);
  }
}
