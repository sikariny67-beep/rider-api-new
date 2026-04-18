const express = require('express');
const mongoose = require('mongoose');
const cors = require('cors');
const app = express();

app.use(cors());
app.use(express.json());

// ลิงก์เชื่อมต่อ (ใช้ User: sikharin ตัวเดิมที่เปิดประตูไว้แล้ว)
const mongoURI = "mongodb+srv://sikharin:Sikarin1234@cluster0.vgyi9bg.mongodb.net/RiderDB?retryWrites=true&w=majority";

mongoose.connect(mongoURI).then(() => console.log('Rider Database Connected!'));

// ออกแบบตารางเก็บข้อมูลออเดอร์
const Order = mongoose.model('Order', {
    date: String,        // วันที่
    orderCount: Number,  // จำนวนงาน
    income: Number,      // รายได้
    target: Number,      // เป้าหมาย (เช่น 60)
    note: String         // หมายเหตุ
});

// ดึงข้อมูลทั้งหมด (GET)
app.get('/api/orders', async (req, res) => {
    try {
        const data = await Order.find().sort({ date: -1 });
        res.json(data);
    } catch (err) {
        res.status(500).json({ error: err.message });
    }
});

// บันทึกข้อมูลใหม่ (POST)
app.post('/api/orders', async (req, res) => {
    try {
        const newOrder = new Order(req.body);
        await newOrder.save();
        res.status(201).json(newOrder);
    } catch (err) {
        res.status(400).json({ error: err.message });
    }
});

app.get('/api', (req, res) => {
    res.send('Rider API System: Online (Sikharin Yonpaph)');
});

module.exports = app;