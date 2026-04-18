import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:percent_indicator/percent_indicator.dart';
import 'package:intl/intl.dart';

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
  bool isLoading = false;

  @override
  void initState() {
    super.initState();
    fetchLatestData();
  }

  // --- 🔄 1. ดึงข้อมูล (แก้เป็น data[0] ให้ดึงของใหม่ล่าสุดที่อยู่บนสุด) ---
  Future<void> fetchLatestData() async {
    setState(() => isLoading = true);
    try {
      String urlWithCacheBuster = "$apiUrl?t=${DateTime.now().millisecondsSinceEpoch}";
      final response = await http.get(Uri.parse(urlWithCacheBuster));
      
      if (response.statusCode == 200) {
        List data = json.decode(response.body);
        if (data.isNotEmpty) {
          setState(() {
            var latest = data[0]; 
            currentOrders = latest['orderCount'] ?? 0;
            todayIncome = latest['income'] ?? 0;
          });
        }
      }
    } catch (e) {
      print("Fetch Error: $e");
    } finally {
      setState(() => isLoading = false);
    }
  }

  // --- 🛠️ 2. บันทึกข้อมูล ---
  Future<void> saveOrder(int count, int income, {String note = "บันทึกจากแอพ"}) async {
    setState(() {
      currentOrders = count;
      todayIncome = income;
    });

    try {
      await http.post(
        Uri.parse(apiUrl),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "date": DateFormat('yyyy-MM-dd HH:mm:ss').format(DateTime.now()),
          "orderCount": count,
          "income": income,
          "target": dailyTarget,
          "note": note
        }),
      );
      fetchLatestData();
    } catch (e) {
      print("Save Error: $e");
    }
  }

  // --- 📝 3. หน้าต่างบวกงาน ---
  void _showAddDialog() {
    TextEditingController countController = TextEditingController();
    TextEditingController incomeController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.grey[900],
        title: Text("🛵 บันทึกงานล่าสุด", style: TextStyle(color: Colors.white)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text("ระบบจะบวกกับยอดเดิมอัตโนมัติ", style: TextStyle(color: Colors.grey[400], fontSize: 14)),
            SizedBox(height: 10),
            TextField(
              controller: countController,
              decoration: InputDecoration(labelText: "เพิ่งวิ่งเสร็จกี่งาน?", labelStyle: TextStyle(color: Colors.greenAccent)),
              keyboardType: TextInputType.number,
              style: TextStyle(color: Colors.white),
            ),
            TextField(
              controller: incomeController,
              decoration: InputDecoration(labelText: "ได้เงินมากี่บาท?", labelStyle: TextStyle(color: Colors.greenAccent)),
              keyboardType: TextInputType.number,
              style: TextStyle(color: Colors.white),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: Text("ยกเลิก", style: TextStyle(color: Colors.grey))),
          ElevatedButton(
            onPressed: () {
              if (countController.text.isNotEmpty && incomeController.text.isNotEmpty) {
                int newCount = currentOrders + int.parse(countController.text);
                int newIncome = todayIncome + int.parse(incomeController.text);
                saveOrder(newCount, newIncome);
                Navigator.pop(context);
              }
            },
            child: Text("บวกยอดเลย!"),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
          ),
        ],
      ),
    );
  }

  // --- 🗑️ 4. หน้าต่างยืนยันการเริ่มวันใหม่ (ล้างข้อมูล) ---
  void _showResetDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.grey[900],
        title: Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: Colors.redAccent),
            SizedBox(width: 10),
            Text("เริ่มวันใหม่?", style: TextStyle(color: Colors.white)),
          ],
        ),
        content: Text("ยอดงานและรายได้ของวันนี้จะถูกรีเซ็ตเป็น 0 เพื่อเริ่มเก็บสถิติใหม่ ยืนยันไหม?", style: TextStyle(color: Colors.grey[300])),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: Text("ยกเลิก", style: TextStyle(color: Colors.grey))),
          ElevatedButton(
            onPressed: () {
              saveOrder(0, 0, note: "เริ่มวันใหม่ (Reset)");
              Navigator.pop(context);
            },
            child: Text("ยืนยันการรีเซ็ต", style: TextStyle(color: Colors.white)),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent),
          ),
        ],
      ),
    );
  }

  // --- 🔥 5. หน้าต่าง Pro Analytics ---
  void _showProAnalytics() {
    double plannedOrders = 30;

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            double estimatedIncome = plannedOrders * 21; 
            double bonus = plannedOrders >= 60 ? 300 : (plannedOrders >= 40 ? 150 : 0);

            return AlertDialog(
              backgroundColor: Colors.black87,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20), side: BorderSide(color: Colors.orangeAccent, width: 1)),
              title: Row(
                children: [
                  Icon(Icons.analytics, color: Colors.orangeAccent),
                  SizedBox(width: 10),
                  Text("Pro Analytics", style: TextStyle(color: Colors.orangeAccent, fontWeight: FontWeight.bold)),
                ],
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Text("🎯 วางแผนรายได้พรุ่งนี้", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                  ),
                  SizedBox(height: 15),
                  Text("เป้าหมาย: ${plannedOrders.toInt()} งาน", style: TextStyle(color: Colors.white, fontSize: 22)),
                  Slider(
                    value: plannedOrders,
                    min: 0,
                    max: 80,
                    divisions: 80,
                    activeColor: Colors.orangeAccent,
                    inactiveColor: Colors.grey[800],
                    label: plannedOrders.toInt().toString(),
                    onChanged: (val) {
                      setState(() => plannedOrders = val);
                    },
                  ),
                  Container(
                    padding: EdgeInsets.all(15),
                    decoration: BoxDecoration(color: Colors.grey[900], borderRadius: BorderRadius.circular(15)),
                    child: Column(
                      children: [
                        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                          Text("ค่ารอบโดยประมาณ:", style: TextStyle(color: Colors.grey[400])),
                          Text("${estimatedIncome.toInt()} ฿", style: TextStyle(color: Colors.greenAccent, fontWeight: FontWeight.bold)),
                        ]),
                        SizedBox(height: 5),
                        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                          Text("อินเซนทีฟ (โบนัส):", style: TextStyle(color: Colors.grey[400])),
                          Text("+${bonus.toInt()} ฿", style: TextStyle(color: Colors.yellowAccent, fontWeight: FontWeight.bold)),
                        ]),
                        Divider(color: Colors.grey[700]),
                        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                          Text("รวมรายได้สุทธิ:", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                          Text("${(estimatedIncome + bonus).toInt()} ฿", style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
                        ]),
                      ],
                    ),
                  )
                ],
              ),
              actions: [
                TextButton(onPressed: () => Navigator.pop(context), child: Text("ปิดหน้าต่าง", style: TextStyle(color: Colors.grey)))
              ],
            );
          }
        );
      }
    );
  }

  @override
  Widget build(BuildContext context) {
    double percent = currentOrders / dailyTarget;
    if (percent > 1.0) percent = 1.0;
    if (percent < 0) percent = 0;

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: Text("Phayak Dashboard 🛵"),
        backgroundColor: Colors.green[800],
        actions: [
          IconButton(
            icon: Icon(Icons.restart_alt, color: Colors.white),
            tooltip: "เริ่มวันใหม่",
            onPressed: _showResetDialog,
          ),
          IconButton(
            icon: Icon(Icons.insights, color: Colors.orangeAccent),
            tooltip: "วิเคราะห์ข้อมูล",
            onPressed: _showProAnalytics,
          ),
          IconButton(
            icon: isLoading ? SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)) : Icon(Icons.refresh),
            onPressed: fetchLatestData,
          )
        ],
      ),
      body: Center(
        child: SingleChildScrollView(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularPercentIndicator(
                radius: 120.0,
                lineWidth: 15.0,
                animation: true,
                animateFromLastPercent: true, 
                percent: percent,
                center: Text("${(percent * 100).toInt()}%", style: TextStyle(fontSize: 40, fontWeight: FontWeight.bold, color: Colors.white)),
                progressColor: Colors.greenAccent,
                backgroundColor: Colors.grey[850]!,
                circularStrokeCap: CircularStrokeCap.round,
                footer: Padding(
                  padding: const EdgeInsets.only(top: 20.0),
                  child: Text("วันนี้วิ่งไป: $currentOrders / $dailyTarget งาน", style: TextStyle(fontSize: 22, color: Colors.greenAccent, fontWeight: FontWeight.bold)),
                ),
              ),
              SizedBox(height: 40),
              Container(
                width: 300,
                child: Card(
                  color: Colors.grey[900],
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20), side: BorderSide(color: Colors.green, width: 0.5)),
                  child: Padding(
                    padding: const EdgeInsets.all(25.0),
                    child: Column(
                      children: [
                        Icon(Icons.payments, color: Colors.yellowAccent, size: 50),
                        SizedBox(height: 10),
                        Text("รายได้สะสมวันนี้", style: TextStyle(color: Colors.grey[400], fontSize: 16)),
                        Text("$todayIncome ฿", style: TextStyle(fontSize: 35, color: Colors.white, fontWeight: FontWeight.bold)),
                      ],
                    ),
                  ),
                ),
              ),
              SizedBox(height: 50),
              Text("Developer: ศิครินทร์ ยนภพ", style: TextStyle(color: Colors.grey[500], fontSize: 14)),
              Text("Student ID: 6700767", style: TextStyle(color: Colors.grey[500], fontSize: 14)),
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showAddDialog,
        icon: Icon(Icons.add, color: Colors.white),
        label: Text("บวกออเดอร์", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.green[700],
      ),
    );
  }
}