const express = require('express');
const cors = require('cors');

const database = require('./database');

const app = express();
const port = process.env.PORT || 3000;

app.use(cors());
app.use(express.json());

function validateSeries(body) {
  return body && body.ownerId && body.title && body.content && body.date;
}

function normalizeSeries(body) {
  return {
    ownerId: body.ownerId,
    title: body.title,
    content: body.content,
    date: body.date,
    rating: Number(body.rating) || 0,
    imageUrl: body.imageUrl || '',
  };
}

app.get('/api/series', async (req, res, next) => {
  try {
    const series = await database.getAllSeries(req.query.ownerId);
    res.json(series);
  } catch (error) {
    next(error);
  }
});

app.get('/api/series/:id', async (req, res, next) => {
  try {
    const item = await database.getSeriesById(Number(req.params.id));
    if (!item) return res.status(404).json({message: 'ไม่พบซีรีส์'});
    res.json(item);
  } catch (error) {
    next(error);
  }
});

app.post('/api/series', async (req, res, next) => {
  try {
    if (!validateSeries(req.body)) {
      return res.status(400).json({message: 'ข้อมูลซีรีส์ไม่ครบ'});
    }

    const item = await database.createSeries(normalizeSeries(req.body));
    res.status(201).json(item);
  } catch (error) {
    next(error);
  }
});

app.put('/api/series/:id', async (req, res, next) => {
  try {
    if (!validateSeries(req.body)) {
      return res.status(400).json({message: 'ข้อมูลซีรีส์ไม่ครบ'});
    }

    const item = await database.updateSeries(
      Number(req.params.id),
      normalizeSeries(req.body),
    );
    if (!item) {
      return res.status(404).json({message: 'ไม่พบซีรีส์หรือไม่มีสิทธิ์แก้ไข'});
    }
    res.json(item);
  } catch (error) {
    next(error);
  }
});

app.delete('/api/series/:id', async (req, res, next) => {
  try {
    const deleted = await database.deleteSeries(
      Number(req.params.id),
      req.query.ownerId,
    );
    if (!deleted) {
      return res.status(404).json({message: 'ไม่พบซีรีส์หรือไม่มีสิทธิ์ลบ'});
    }
    res.status(204).send();
  } catch (error) {
    next(error);
  }
});

app.use((error, req, res, next) => {
  console.error(error);
  res.status(500).json({message: 'เกิดข้อผิดพลาดที่ server'});
});

app.listen(port, '0.0.0.0', () => {
  console.log(`Series REST API running on port ${port}`);
  console.log(
    process.env.DATABASE_URL
      ? 'Database mode: Supabase PostgreSQL'
      : 'Database mode: local JSON file',
  );
});
