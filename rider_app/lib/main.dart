import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:percent_indicator/percent_indicator.dart';
import 'package:intl/intl.dart'; // อย่าลืมลง flutter pub add intl นะถ้ามันฟ้อง

void main() => runApp(MaterialApp(
  home: RiderDashboard(), 
  theme: ThemeData.dark(),
  debugShowCheckedModeBanner: false,
));

class RiderDashboard extends StatefulWidget {
  @override
  _RiderDashboardState createState() => _RiderDashboardState();
}

class _RiderDashboardState extends State<RiderDashboard> {
  final String apiUrl = "https://rider-api-new.vercel.app/api/orders";
  
  int currentOrders = 0;
  int todayIncome = 0;
  int dailyTarget = 60;

  @override
  void initState() {
    super.initState();
    fetchLatestData();
  }

  Future<void> fetchLatestData() async {
    try {
      final response = await http.get(Uri.parse(apiUrl));
      if (response.statusCode == 200) {
        List data = json.decode(response.body);
        if (data.isNotEmpty) {
          setState(() {
            currentOrders = data[0]['orderCount'] ?? 0;
            todayIncome = data[0]['income'] ?? 0;
          });
        }
      }
    } catch (e) { print(e); }
  }

  // --- 🛠️ ฟังก์ชันส่งข้อมูลไปหลังบ้าน (POST) ---
  Future<void> saveOrder(int count, int income) async {
    try {
      await http.post(
        Uri.parse(apiUrl),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "date": DateFormat('yyyy-MM-dd').format(DateTime.now()),
          "orderCount": count,
          "income": income,
          "target": dailyTarget,
          "note": "บันทึกจากแอพ"
        }),
      );
      fetchLatestData(); // บันทึกเสร็จแล้วดึงข้อมูลใหม่มาโชว์ทันที
    } catch (e) { print(e); }
  }

  // --- 📝 หน้าต่าง Popup ให้กรอกข้อมูล ---
  void _showAddDialog() {
    TextEditingController countController = TextEditingController();
    TextEditingController incomeController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text("บันทึกงานวันนี้ 🛵"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: countController, decoration: InputDecoration(labelText: "จำนวนออเดอร์"), keyboardType: TextInputType.number),
            TextField(controller: incomeController, decoration: InputDecoration(labelText: "รายได้ทั้งหมด"), keyboardType: TextInputType.number),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: Text("ยกเลิก")),
          ElevatedButton(
            onPressed: () {
              saveOrder(int.parse(countController.text), int.parse(incomeController.text));
              Navigator.pop(context);
            },
            child: Text("บันทึกข้อมูล"),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    double percent = currentOrders / dailyTarget;
    if (percent > 1.0) percent = 1.0;

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: Text("Phayak Dashboard 🛵"),
        backgroundColor: Colors.green[700],
        actions: [IconButton(icon: Icon(Icons.refresh), onPressed: fetchLatestData)],
      ),
      body: Center(
        child: SingleChildScrollView(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularPercentIndicator(
                radius: 120.0, lineWidth: 15.0, animation: true,
                percent: percent,
                center: Text("${(percent * 100).toInt()}%", style: TextStyle(fontSize: 40, fontWeight: FontWeight.bold)),
                progressColor: Colors.greenAccent, backgroundColor: Colors.grey[800]!,
                circularStrokeCap: CircularStrokeCap.round,
                footer: Padding(
                  padding: const EdgeInsets.only(top: 20.0),
                  child: Text("วันนี้วิ่งไป: $currentOrders / $dailyTarget งาน", 
                    style: TextStyle(fontSize: 20, color: Colors.greenAccent, fontWeight: FontWeight.bold)),
                ),
              ),
              SizedBox(height: 40),
              Container(
                width: 300,
                child: Card(
                  color: Colors.grey[900],
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                  child: Padding(
                    padding: const EdgeInsets.all(20.0),
                    child: Column(
                      children: [
                        Icon(Icons.account_balance_wallet, color: Colors.yellow, size: 50),
                        SizedBox(height: 10),
                        Text("รายได้สะสมวันนี้", style: TextStyle(color: Colors.grey)),
                        Text("$todayIncome บาท", style: TextStyle(fontSize: 35, color: Colors.white, fontWeight: FontWeight.bold)),
                      ],
                    ),
                  ),
                ),
              ),
              SizedBox(height: 60),
              Text("Developer: ศิครินทร์ ยนภพ", style: TextStyle(color: Colors.grey[600])),
              Text("Student ID: 6700767", style: TextStyle(color: Colors.grey[600])),
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddDialog, // กดแล้วเปิดหน้ากรอกข้อมูล
        child: Icon(Icons.add, color: Colors.white),
        backgroundColor: Colors.green[700],
      ),
    );
  }
}