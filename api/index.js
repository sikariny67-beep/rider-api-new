const express = require('express');
const mongoose = require('mongoose');
const cors = require('cors');
const app = express();

app.use(cors());
app.use(express.json());

const mongoURI = "mongodb+srv://sikharin:Sikarin1234@cluster0.vgyi9bg.mongodb.net/RiderDB?retryWrites=true&w=majority";

let isConnected = false;
const connectDB = async () => {
    if (isConnected) return;
    try {
        await mongoose.connect(mongoURI, { serverSelectionTimeoutMS: 5000 });
        isConnected = true;
        console.log('MongoDB Connected');
    } catch (err) {
        console.error('DB Connection Error:', err.message);
    }
};

const Order = mongoose.model('Order', {
    date: String,
    orderCount: Number,
    income: Number,
    target: Number,
    note: String
});

// ดึงข้อมูล (GET) - เรียงอันใหม่ไว้บนสุด
app.get('/api/orders', async (req, res) => {
    await connectDB();
    try {
        const data = await Order.find().sort({ _id: -1 });
        res.json(data);
    } catch (err) {
        res.status(500).json({ error: "Database error" });
    }
});

// บันทึกข้อมูล (POST)
app.post('/api/orders', async (req, res) => {
    await connectDB();
    try {
        const newOrder = new Order(req.body);
        await newOrder.save();
        res.status(201).json(newOrder);
    } catch (err) {
        res.status(400).json({ error: "Save error" });
    }
});

// 🔥 อัปเดตข้อมูล (PUT) - เพิ่มมาใหม่สำหรับแก้ไข
app.put('/api/orders/:id', async (req, res) => {
    await connectDB();
    try {
        const updatedOrder = await Order.findByIdAndUpdate(req.params.id, req.body, { new: true });
        res.json(updatedOrder);
    } catch (err) {
        res.status(400).json({ error: "Update error" });
    }
});

// 🔥 ลบข้อมูล (DELETE) - เพิ่มมาใหม่สำหรับลบ
app.delete('/api/orders/:id', async (req, res) => {
    await connectDB();
    try {
        await Order.findByIdAndDelete(req.params.id);
        res.json({ message: "Deleted successfully" });
    } catch (err) {
        res.status(400).json({ error: "Delete error" });
    }
});

app.get('/api', (req, res) => {
    res.send('Rider API is Online (Sikharin)');
});

module.exports = app;