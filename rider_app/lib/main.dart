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
  int dailyTarget = 100;
  bool isLoading = false;

  @override
  void initState() {
    super.initState();
    fetchLatestData();
  }

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
            icon: Icon(Icons.history, color: Colors.white),
            tooltip: "ประวัติการวิ่งงาน",
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => HistoryPage(apiUrl: apiUrl)),
              ).then((_) => fetchLatestData()); // พอกลับมาหน้าหลักให้ดึงข้อมูลใหม่เผื่อมีการแก้ไข
            },
          ),
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
              Text("Developer: Sikarin & sorasak", style: TextStyle(color: Colors.grey[500], fontSize: 14)),
              Text("Student ID: 6700767 & 6700772", style: TextStyle(color: Colors.grey[500], fontSize: 14)),
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

// =========================================================================
//   HistoryPage (หน้าประวัติการวิ่งงาน + ลบ/แก้ไข) เด้อออ
// =========================================================================

class HistoryPage extends StatefulWidget {
  final String apiUrl;
  HistoryPage({required this.apiUrl});

  @override
  _HistoryPageState createState() => _HistoryPageState();
}

class _HistoryPageState extends State<HistoryPage> {
  List historyData = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    fetchHistory();
  }

  Future<void> fetchHistory() async {
    setState(() => isLoading = true);
    try {
      String urlWithCacheBuster = "${widget.apiUrl}?t=${DateTime.now().millisecondsSinceEpoch}";
      final response = await http.get(Uri.parse(urlWithCacheBuster));
      if (response.statusCode == 200) {
        setState(() {
          historyData = json.decode(response.body);
          isLoading = false;
        });
      }
    } catch (e) {
      print("Fetch History Error: $e");
      setState(() => isLoading = false);
    }
  }

  
  Future<void> deleteOrder(String id) async {
    try {
      final response = await http.delete(Uri.parse("${widget.apiUrl}/$id"));
      if (response.statusCode == 200) {
        fetchHistory(); 
      }
    } catch (e) {
      print("Delete Error: $e");
    }
  }

  
  Future<void> updateOrder(String id, int newCount, int newIncome) async {
    try {
      final response = await http.put(
        Uri.parse("${widget.apiUrl}/$id"),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "orderCount": newCount,
          "income": newIncome,
          "note": "แก้ไขข้อมูลแล้ว"
        }),
      );
      if (response.statusCode == 200) {
        fetchHistory();
      }
    } catch (e) {
      print("Update Error: $e");
    }
  }

  
  void _confirmDelete(String id) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.grey[900],
        title: Text("ลบรายการนี้?", style: TextStyle(color: Colors.white)),
        content: Text("ข้อมูลจะหายไปจากระบบถาวร", style: TextStyle(color: Colors.grey[400])),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: Text("ยกเลิก", style: TextStyle(color: Colors.grey))),
          ElevatedButton(
            onPressed: () {
              deleteOrder(id);
              Navigator.pop(context);
            },
            child: Text("ลบทิ้งเลย"),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent),
          ),
        ],
      ),
    );
  }

  
  void _showEditDialog(String id, int currentCount, int currentIncome) {
    TextEditingController countController = TextEditingController(text: currentCount.toString());
    TextEditingController incomeController = TextEditingController(text: currentIncome.toString());

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.grey[900],
        title: Text("แก้ไขข้อมูล ✏️", style: TextStyle(color: Colors.white)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: countController,
              decoration: InputDecoration(labelText: "ยอดออเดอร์สะสม", labelStyle: TextStyle(color: Colors.orangeAccent)),
              keyboardType: TextInputType.number,
              style: TextStyle(color: Colors.white),
            ),
            TextField(
              controller: incomeController,
              decoration: InputDecoration(labelText: "ยอดเงินสะสม", labelStyle: TextStyle(color: Colors.orangeAccent)),
              keyboardType: TextInputType.number,
              style: TextStyle(color: Colors.white),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: Text("ยกเลิก", style: TextStyle(color: Colors.grey))),
          ElevatedButton(
            onPressed: () {
              updateOrder(id, int.parse(countController.text), int.parse(incomeController.text));
              Navigator.pop(context);
            },
            child: Text("บันทึกการแก้ไข"),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.orange),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: Text("ประวัติการวิ่งงาน 📜"),
        backgroundColor: Colors.grey[900],
      ),
      body: isLoading
          ? Center(child: CircularProgressIndicator(color: Colors.greenAccent))
          : historyData.isEmpty
              ? Center(child: Text("ยังไม่มีประวัติการวิ่งงาน", style: TextStyle(color: Colors.grey)))
              : ListView.builder(
                  padding: EdgeInsets.all(10),
                  itemCount: historyData.length,
                  itemBuilder: (context, index) {
                    var item = historyData[index];
                    return Card(
                      color: Colors.grey[850],
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: Colors.green[800],
                          child: Icon(Icons.two_wheeler, color: Colors.white, size: 20),
                        ),
                        title: Text("${item['orderCount']} งาน | ${item['income']} บาท", 
                          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18)),
                        subtitle: Text("${item['date']} \nหมายเหตุ: ${item['note'] ?? '-'}", 
                          style: TextStyle(color: Colors.grey[400], fontSize: 12)),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: Icon(Icons.edit, color: Colors.orangeAccent),
                              onPressed: () => _showEditDialog(item['_id'], item['orderCount'], item['income']),
                            ),
                            IconButton(
                              icon: Icon(Icons.delete, color: Colors.redAccent),
                              onPressed: () => _confirmDelete(item['_id']),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
    );
  }
}