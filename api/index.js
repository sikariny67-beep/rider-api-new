const express = require('express');
const mongoose = require('mongoose');
const cors = require('cors');
const app = express();

app.use(cors());
app.use(express.json());

// เช็ครหัสผ่านตรงนี้อีกรอบนะ Sikarin1234
const mongoURI = "mongodb+srv://sikharin:Sikarin1234@cluster0.vgyi9bg.mongodb.net/RiderDB?retryWrites=true&w=majority";

// เชื่อมต่อแบบมีระบบป้องกันการค้าง
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

app.get('/api/orders', async (req, res) => {
    await connectDB();
    try {
        const data = await Order.find().sort({ date: -1 });
        res.json(data);
    } catch (err) {
        res.status(500).json({ error: "Database error" });
    }
});

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

app.get('/api', (req, res) => {
    res.send('Rider API is Online (Sikharin)');
});

module.exports = app;