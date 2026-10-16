const fs = require('fs');
const path = require('path');
const { Pool } = require('pg');

const dataFile = path.join(__dirname, 'data', 'series.json');
const usesPostgres = Boolean(process.env.DATABASE_URL);

// เชื่อมต่อ Supabase PostgreSQL เมื่อมี DATABASE_URL
const pool = usesPostgres
  ? new Pool({
      connectionString: process.env.DATABASE_URL,
      ssl: { rejectUnauthorized: false },
      max: 5,
    })
  : null;

// แปลงชื่อคอลัมน์ของ PostgreSQL ให้เป็นรูปแบบที่แอปใช้
function mapDatabaseRow(row) {
  return {
    id: Number(row.id),
    ownerId: row.owner_id,
    title: row.title,
    content: row.content,
    date: row.series_date,
    rating: Number(row.rating),
    imageUrl: row.image_url,
  };
}

// ใช้ไฟล์ JSON เป็นฐานข้อมูลสำรองเมื่อรันในเครื่อง
function readLocalSeries() {
  return JSON.parse(fs.readFileSync(dataFile, 'utf8'));
}

function writeLocalSeries(series) {
  fs.writeFileSync(dataFile, JSON.stringify(series, null, 2));
}

// -----------------------------------------------------------------------------
// คำสั่ง CRUD สำหรับซีรีส์
// -----------------------------------------------------------------------------
async function getAllSeries(ownerId) {
  if (usesPostgres) {
    const values = ownerId ? [ownerId] : [];
    const query = ownerId
      ? 'SELECT * FROM public.series WHERE owner_id = $1 ORDER BY id DESC'
      : 'SELECT * FROM public.series ORDER BY id DESC';
    const result = await pool.query(query, values);
    return result.rows.map(mapDatabaseRow);
  }

  const series = readLocalSeries();
  return ownerId ? series.filter((item) => item.ownerId === ownerId) : series;
}

async function getSeriesById(id, ownerId) {
  if (usesPostgres) {
    const result = await pool.query(
      'SELECT * FROM public.series WHERE id = $1 AND owner_id = $2',
      [id, ownerId],
    );
    return result.rows[0] ? mapDatabaseRow(result.rows[0]) : null;
  }

  return readLocalSeries().find(
    (item) => item.id === id && item.ownerId === ownerId,
  ) || null;
}

async function createSeries(data) {
  if (usesPostgres) {
    const result = await pool.query(
      `INSERT INTO public.series
        (owner_id, title, content, series_date, rating, image_url)
       VALUES ($1, $2, $3, $4, $5, $6)
       RETURNING *`,
      [
        data.ownerId,
        data.title,
        data.content,
        data.date,
        data.rating,
        data.imageUrl,
      ],
    );
    return mapDatabaseRow(result.rows[0]);
  }

  const series = readLocalSeries();
  const nextId = series.length === 0
    ? 1
    : Math.max(...series.map((item) => item.id)) + 1;
  const newItem = {id: nextId, ...data};
  series.push(newItem);
  writeLocalSeries(series);
  return newItem;
}

async function updateSeries(id, data) {
  if (usesPostgres) {
    const result = await pool.query(
      `UPDATE public.series
       SET title = $1,
           content = $2,
           series_date = $3,
           rating = $4,
           image_url = $5
       WHERE id = $6 AND owner_id = $7
       RETURNING *`,
      [
        data.title,
        data.content,
        data.date,
        data.rating,
        data.imageUrl,
        id,
        data.ownerId,
      ],
    );
    return result.rows[0] ? mapDatabaseRow(result.rows[0]) : null;
  }

  const series = readLocalSeries();
  const index = series.findIndex((item) => item.id === id);
  if (index === -1 || series[index].ownerId !== data.ownerId) return null;

  series[index] = {id, ...data};
  writeLocalSeries(series);
  return series[index];
}

async function deleteSeries(id, ownerId) {
  if (usesPostgres) {
    const result = await pool.query(
      'DELETE FROM public.series WHERE id = $1 AND owner_id = $2 RETURNING id',
      [id, ownerId],
    );
    return result.rowCount > 0;
  }

  const series = readLocalSeries();
  const index = series.findIndex(
    (item) => item.id === id && item.ownerId === ownerId,
  );
  if (index === -1) return false;

  series.splice(index, 1);
  writeLocalSeries(series);
  return true;
}

module.exports = {
  createSeries,
  deleteSeries,
  getAllSeries,
  getSeriesById,
  updateSeries,
};
